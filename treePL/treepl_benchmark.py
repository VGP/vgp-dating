#!/usr/bin/env python3
"""Seed-nominated optimizer screening and independent single-value CV for one treePL config."""
import argparse
import concurrent.futures as futures
import csv
import fcntl
import hashlib
import json
import math
import itertools
import random
import os
from pathlib import Path
import re
import shutil
import signal
import statistics
import subprocess
import sys
import threading
import tempfile
import time

HERE = Path(__file__).resolve().parent
DEFAULT_SEEDS = (1729, 555136393, 1587025888, 104729, 130363)
OBJECTIVE = re.compile(r'^after opt calc:\s*(\S+)', re.M)
SCORE = re.compile(r'^chisq: \(([^)]+)\)\s*(\S+)', re.M)
PRINT_LOCK = threading.Lock()
STOP = threading.Event()
LOG_PATH = None
PUBLICATION_COMPLETE = False


def log(message):
    with PRINT_LOCK:
        line = time.strftime('[%Y-%m-%d %H:%M:%S] ')+message
        print(line, flush=True)
        if LOG_PATH is not None:
            with LOG_PATH.open('a') as handle:
                handle.write(line+'\n')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def atomic(path, text):
    path = Path(path)
    tmp = path.with_name(path.name+'.tmp')
    tmp.write_text(text)
    os.replace(tmp, path)


def save(path, value):
    atomic(path, json.dumps(value, indent=2, allow_nan=False)+'\n')


def table(path, rows):
    if not rows:
        return
    with Path(path).open('w', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]), delimiter='\t')
        writer.writeheader()
        writer.writerows(rows)


def settings(text):
    result = {}
    for raw in text.splitlines():
        line = raw.split('#', 1)[0].strip()
        if not line:
            continue
        key, sep, value = line.partition('=')
        key = key.strip()
        if key in ('mrca', 'min', 'max'):
            continue
        if key in result:
            raise ValueError(f'Duplicate setting: {key}')
        result[key] = value.strip() if sep else True
    return result


def calibration_check(text, master, topology):
    column = 'node_'+topology.replace('.', '_')
    with master.open() as handle:
        reader = csv.DictReader(handle)
        if column not in reader.fieldnames:
            raise ValueError(f'Master lacks {column}')
        rows = list(reader)
    if len({r['calibration_id'] for r in rows}) != len(rows):
        raise ValueError('Duplicate master calibration IDs')
    expected = {r['node_name']: r for r in rows if r[column].strip()}
    if len(expected) != sum(bool(r[column].strip()) for r in rows):
        raise ValueError('Duplicate master calibration names')
    actual = {key: {} for key in ('mrca', 'min', 'max')}
    for raw in text.splitlines():
        p = raw.split('#', 1)[0].replace('=', ' ').split()
        if not p or p[0] not in actual:
            continue
        if len(p)<3 or p[1] in actual[p[0]]:
            raise ValueError('Malformed or duplicate calibration')
        actual[p[0]][p[1]] = p[2:]
    for key, values in actual.items():
        if set(values) != set(expected):
            raise ValueError(f'{key} calibration names differ from master')
        for name, row in expected.items():
            value = values[name]
            valid = (len(value)==2 and set(value)=={row['taxon1_accession'], row['taxon2_accession']}) if key=='mrca' else (
                len(value)==1 and float(value[0])==float(row[key+'_ma']))
            if not valid:
                raise ValueError(f'{name} {key} differs from master')


def config_text(original, updates, flags):
    keys = set(updates) | set(flags) | {'prime', 'thorough', 'cv', 'randomcv', 'cvstart', 'cvstop', 'cvmultstep', 'cvoutfile'}
    replacements = {k: f'{k} = {v}' for k, v in updates.items()}
    replacements.update({k: k if enabled else '#'+k for k, enabled in flags.items()})
    replacements['prime'] = '#prime'
    lines, seen = [], set()
    for raw in original.splitlines():
        active = raw.lstrip().lstrip('#').strip().split('#', 1)[0].strip()
        key = active.split('=', 1)[0].strip()
        if key in replacements and key not in seen:
            lines.append(replacements[key])
            seen.add(key)
        elif key not in keys:
            lines.append(raw)
    missing = [line for key, line in replacements.items() if key not in seen]
    if missing:
        # Keep any newly introduced controls ahead of the calibration block.
        index = next((i for i, line in enumerate(lines) if line.startswith('# BEGIN MASTER CALIBRATIONS')
                      or re.match(r'^\s*mrca\s*=', line)), len(lines))
        lines[index:index] = missing+['']
    return '\n'.join(lines).rstrip()+'\n'


def terminate(proc):
    if proc.poll() is not None:
        return
    try:
        os.killpg(proc.pid, signal.SIGTERM)
        proc.wait(timeout=5)
    except ProcessLookupError:
        proc.wait()
    except subprocess.TimeoutExpired:
        os.killpg(proc.pid, signal.SIGKILL)
        proc.wait()


def checked(command, path):
    with path.open('w') as out:
        proc = subprocess.Popen(command, stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            while proc.poll() is None:
                if STOP.wait(0.2):
                    raise InterruptedError('Interrupted')
        except BaseException:
            terminate(proc)
            raise
    if proc.returncode:
        raise RuntimeError(f'Command failed; see {path}')


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('config', type=Path)
    seeds = p.add_mutually_exclusive_group()
    seeds.add_argument('--seed-count', type=int, default=5, help='one global seed count for screening, CV and final fits (default: 5)')
    seeds.add_argument('--seeds', help='explicit shared seeds, comma-separated')
    grid = p.add_mutually_exclusive_group()
    grid.add_argument('--smoothing-values', help='positive smoothing values, comma-separated')
    grid.add_argument('--smoothing-range', nargs=3, metavar=('HIGH', 'LOW', 'COUNT'), help='log-spaced grid; default: 1000 1e-7 11')
    p.add_argument('--optimizer-pairs', default='all', help='all 36 pairs, or comma-separated opt/optad pairs such as 1/3,2/3')
    p.add_argument('--details', default='00,01,10,11', help='moredetail/moredetailad bit pairs, comma-separated')
    p.add_argument('--pliter', type=int, default=50, help='screening and CV full-tree iteration budget')
    p.add_argument('--cviter', type=int, default=3, help='iterations per CV leave-out')
    p.add_argument('--final-pliter', type=int, default=200, help='final iteration check budget; must be >= pliter')
    p.add_argument('--jobs', type=int, help='concurrent jobs for both stages unless --cv-jobs overrides; PL default: 10')
    p.add_argument('--threads', type=int, help='threads per fit for both stages unless --cv-threads overrides; PL default: 1')
    p.add_argument('--cv-jobs', type=int, help='CV concurrent jobs (default: 5)')
    p.add_argument('--cv-threads', type=int, help='CV threads per fit (default: 2)')
    p.add_argument('--thorough', action='store_true', help='enable thorough in screening and CV; final comparison always tests both modes')
    p.add_argument('--outlier-factor', type=float, default=1000, help='exclude scores above this multiple of their replicate median')
    p.add_argument('--keep-work', action='store_true', help='retain per-fit working files after successful publication')
    p.add_argument('--dry-run', action='store_true')
    p.add_argument('--master', type=Path, default=HERE.parent/'calibrations/master_calibrations.csv')
    a = p.parse_args()
    available = len(os.sched_getaffinity(0)) if hasattr(os, 'sched_getaffinity') else (os.cpu_count() or 1)
    requested_jobs, requested_threads = a.jobs, a.threads
    a.threads = requested_threads if requested_threads is not None else 1
    a.jobs = requested_jobs if requested_jobs is not None else min(10, max(1, available//max(1, a.threads)))
    if a.cv_threads is None:
        a.cv_threads = requested_threads if requested_threads is not None else min(2, available)
    if a.cv_jobs is None:
        a.cv_jobs = requested_jobs if requested_jobs is not None else min(5, max(1, available//max(1, a.cv_threads)))
    try:
        if min(a.jobs, a.threads, a.cv_jobs, a.cv_threads, a.pliter, a.cviter, a.final_pliter, a.seed_count) < 1:
            raise ValueError('counts, threads and iteration budgets must be positive')
        if a.final_pliter < a.pliter:
            raise ValueError('final-pliter must be >= pliter')
        if not math.isfinite(a.outlier_factor) or a.outlier_factor <= 1:
            raise ValueError('outlier-factor must be finite and > 1')
        if a.seeds is not None:
            a.seeds = [int(x) for x in a.seeds.split(',')]
        else:
            a.seeds = list(DEFAULT_SEEDS[:a.seed_count])
            generator = random.Random(1729)
            while len(a.seeds) < a.seed_count:
                seed = generator.randrange(1, 2147483648)
                if seed not in a.seeds:
                    a.seeds.append(seed)
        if not a.seeds or len(set(a.seeds)) != len(a.seeds) or any(s < 1 or s > 2147483647 for s in a.seeds):
            raise ValueError('seeds must be distinct integers in 1..2147483647')
        a.seed_count = len(a.seeds)
        if a.smoothing_values is not None:
            values = [float(x) for x in a.smoothing_values.split(',')]
        else:
            high, low, count = a.smoothing_range or ('1000', '1e-7', '11')
            high, low, count = float(high), float(low), int(count)
            if not (math.isfinite(high) and math.isfinite(low) and high >= low > 0 and count >= 1):
                raise ValueError('range requires finite HIGH >= LOW > 0 and a positive integer COUNT')
            if count == 1 and high != low:
                raise ValueError('a one-point range must have equal bounds; alternatively use --smoothing-values')
            values = [high] if count == 1 else [10**(math.log10(high)+(math.log10(low)-math.log10(high))*i/(count-1)) for i in range(count)]
            values[0], values[-1] = high, low
        if not values or any(not math.isfinite(s) or s <= 0 for s in values) or len(set(values)) != len(values):
            raise ValueError('smoothing values must be finite, positive and distinct')
        a.smoothing = sorted(values, reverse=True)
        pairs = list(itertools.product(range(6), repeat=2)) if a.optimizer_pairs == 'all' else [tuple(map(int, x.split('/'))) for x in a.optimizer_pairs.split(',')]
        details = a.details.split(',')
        if len(set(pairs)) != len(pairs) or any(len(x) != 2 or any(v not in range(6) for v in x) for x in pairs):
            raise ValueError('optimizer pairs must be distinct opt/optad pairs with values 0..5')
        if len(set(details)) != len(details) or any(d not in ('00', '01', '10', '11') for d in details):
            raise ValueError('details must contain distinct choices from 00,01,10,11')
        a.candidates = [tuple(pair)+tuple(map(int, d)) for pair in pairs for d in details]
    except (ValueError, OverflowError) as error:
        p.error(str(error))
    return a


def assess(rows, field, requested, factor):
    """Classify gross outliers within one comparable group; never pool smoothing levels."""
    valid = [r for r in rows if r['status'] == 'complete' and r.get(field) is not None and math.isfinite(r[field])]
    median = statistics.median(r[field] for r in valid) if valid else None
    filter_enabled = requested >= 3 and len(valid) >= 3 and median > 0
    for r in rows:
        r['assessment'] = 'failed' if r['status'] != 'complete' else 'retained'
        if r in valid and filter_enabled and r[field] > median*factor:
            r['assessment'] = 'outlier'
            log(f'OUTLIER: {r["stage"]} smooth={r["smooth"]:g}, optimizer={r["candidate"]}, seed={r["seed"]}, {field}={r[field]:g}; excluded from selection')
    kept = [r for r in valid if r['assessment'] == 'retained']
    usable = len(kept) > requested//2
    return kept, dict(requested=requested, valid=len(valid), retained=len(kept),
                      outliers=sum(r['assessment'] == 'outlier' for r in rows),
                      failures=len(rows)-len(valid), filter_median=median, filter_enabled=filter_enabled, usable=usable)


def stage_eta(started, completed, total):
    """Observed stage throughput; not a prediction for unseen CV/thorough workloads."""
    if completed >= total:
        return 'stage ETA 0m'
    if not completed:
        return 'stage ETA estimating (no completed fits yet)'
    seconds = max(0, (time.monotonic()-started)*(total-completed)/completed)
    minutes = math.ceil(seconds/60)
    return f'stage ETA ~{minutes//60}h {minutes%60:02d}m (provisional; current stage only)'


def choose_optimizer(summaries):
    """Median, worst seed within numerical ties, then runtime and stable identifier."""
    choices = [r for r in summaries if r['usable']]
    if not choices:
        return None
    for field in ('median', 'worst'):
        best = min(r[field] for r in choices)
        tolerance = max(abs(best)*1e-6, 1e-8)
        choices = [r for r in choices if r[field]-best <= tolerance]
    return min(choices, key=lambda r: (r['seconds'], r['candidate']))


class Benchmark:
    def __init__(self, args, root, original, tree, binary, rscript):
        self.a, self.root, self.original = args, root, original
        self.tree, self.binary, self.rscript = tree, binary, rscript
        self.tips = int(re.search(r'Input valid: (\d+) tips', (root/'input_validation.log').read_text())[1])
        self.rows = []

    def job(self, stage, index, candidate, seed, pliter, thorough=None):
        return dict(stage=stage, index=index, smooth=self.a.smoothing[index], candidate=list(candidate), seed=seed,
                    pliter=pliter, threads=self.a.cv_threads if stage == 'cv' else self.a.threads,
                    thorough=self.a.thorough if thorough is None else thorough)

    def directory(self, fit):
        path = self.root/fit['fit_id']
        if path.is_symlink() or not path.resolve().is_relative_to(self.root.resolve()):
            raise RuntimeError('Unsafe fit identifier')
        return path

    def cv_scores(self, directory, expected, text):
        scores = [(float(x), float(y)) for x, y in SCORE.findall(text)]
        if not (directory/'cv.out').is_file():
            raise RuntimeError('Missing saved CV score file')
        saved = [(float(x), float(y)) for x, y in SCORE.findall((directory/'cv.out').read_text())]
        for points in (scores, saved):
            if len(points) != 1 or not math.isclose(points[0][0], expected, rel_tol=1e-5):
                raise RuntimeError('CV did not produce exactly one score at the requested smoothing')
            if not math.isfinite(points[0][1]) or points[0][1] < 0:
                raise RuntimeError('Non-finite or negative CV score')
        if not math.isclose(scores[0][1], saved[0][1], rel_tol=5e-6, abs_tol=1e-12):
            raise RuntimeError('CV log and saved score disagree beyond output precision')
        return scores[0][1]

    def fit(self, job):
        if STOP.is_set():
            raise InterruptedError('Interrupted')
        r = dict(job, status='running', assessment='pending', objective=None, score=None,
                 seconds=None, negative_returns=0, reason='')
        tag = '-'.join(map(str, r['candidate']))+f'_seed-{r["seed"]}_thorough-{int(r["thorough"])}'
        directory = self.root/r['stage']/f's{r["index"]:03d}'/tag
        directory.mkdir(parents=True, exist_ok=False)
        r['fit_id'] = str(directory.relative_to(self.root))
        opt, optad, detail, detailad = r['candidate']
        updates = dict(treefile=self.tree, outfile='result.tre', seed=r['seed'], smooth=format(r['smooth'], '.17g'),
                       pliter=r['pliter'], cviter=self.a.cviter, nthreads=r['threads'], opt=opt, optad=optad)
        flags = dict(moredetail=bool(detail), moredetailad=bool(detailad), thorough=r['thorough'])
        cv = r['stage'] == 'cv'
        if cv:
            updates.update(cvstart=updates['smooth'], cvstop=updates['smooth'], cvmultstep=.1, cvoutfile='cv.out')
            flags['cv'] = True
        (directory/'fit.config').write_text(config_text(self.original, updates, flags))
        save(directory/'result.json', r)
        start = time.monotonic()
        log(f'{r["stage"]} smooth={r["smooth"]:g} {tag}: starting; pliter={r["pliter"]}, thorough={r["thorough"]}, threads={r["threads"]}')
        try:
            cv_finished = cv_stopped = False
            pending, leaves, have_score = '', 0, False
            next_report = start+30
            with (directory/'run.log').open('w') as out, (directory/'run.log').open(errors='replace') as incoming:
                proc = subprocess.Popen([self.binary, 'fit.config'], cwd=directory, stdout=out,
                                        stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    while True:
                        ended = proc.poll() is not None
                        pending += incoming.read()
                        chunks = pending.split('\n'); pending = chunks.pop()
                        for line in chunks:
                            if line.startswith('curcv:'):
                                leaves = 0
                            elif re.match(r'^cv: \d+', line):
                                leaves += 1
                            if cv and SCORE.match(line):
                                have_score = True
                                log(f'CV smooth={r["smooth"]:g}, seed={r["seed"]}: {line}')
                            # This follows the completed CV loop and its flushed score file.
                            if cv and have_score and line.startswith('smoothing:'):
                                r['score'] = self.cv_scores(directory, r['smooth'], (directory/'run.log').read_text(errors='replace'))
                                cv_finished = True
                        if cv_finished and not ended:
                            terminate(proc)
                            cv_stopped = True
                            break
                        if ended:
                            break
                        if STOP.wait(.2):
                            raise InterruptedError('Interrupted')
                        if time.monotonic() >= next_report:
                            activity = f'; ~{leaves}/{self.tips} leave-outs ({100*leaves/self.tips:.1f}%)' if cv else ''
                            log(f'{r["stage"]} smooth={r["smooth"]:g} {tag}: running {time.monotonic()-start:.0f}s{activity}')
                            next_report = time.monotonic()+30
                except BaseException:
                    terminate(proc)
                    raise
            text = (directory/'run.log').read_text(errors='replace')
            r['negative_returns'] = len(re.findall(r'^result:\s*-\d+', text, re.M))
            if proc.returncode and not cv_stopped:
                raise RuntimeError(f'treePL exited {proc.returncode}')
            if cv:
                r['score'] = self.cv_scores(directory, r['smooth'], text)
                r['post_cv_fit_skipped'] = cv_stopped
                names = ('cv.out', 'fit.config', 'run.log')
            else:
                values = OBJECTIVE.findall(text)
                r['raw_objective'] = values[-1] if values else ''
                objective = float(values[-1]) if values else math.nan
                if not math.isfinite(objective) or not (directory/'result.tre').is_file():
                    raise RuntimeError('Missing finite final objective or dated tree')
                r['objective'] = objective
                checked([self.rscript, str(HERE/'treepl_validate.R'), str(self.tree), str(directory/'fit.config'),
                         str(directory/'result.tre'), str(directory/'ages.tsv')], directory/'validation.log')
                names = ('result.tre', 'ages.tsv', 'fit.config', 'run.log')
            r.update(status='complete', artifacts={name: digest(directory/name) for name in names})
        except (RuntimeError, ValueError) as error:
            r.update(status='failed', assessment='failed', reason=str(error))
            log(f'FAILED: {r["stage"]} smooth={r["smooth"]:g} {tag}: {error}; retained for review')
        r['seconds'] = round(time.monotonic()-start, 3)
        save(directory/'result.json', r)
        if r['status'] == 'complete':
            log(f'{r["stage"]} smooth={r["smooth"]:g} {tag}: complete in {r["seconds"]:.1f}s; {"CV score" if cv else "objective"}={r["score"] if cv else r["objective"]}')
        return r

    def batch(self, pool, jobs, label):
        pending = {pool.submit(self.fit, job) for job in jobs}
        results = []
        started = time.monotonic()
        try:
            while pending:
                done, pending = futures.wait(pending, timeout=30, return_when=futures.FIRST_COMPLETED)
                if not done:
                    log(f'{label}: {len(results)}/{len(jobs)} complete; '+stage_eta(started, len(results), len(jobs)))
                for future in done:
                    r = future.result(); results.append(r); self.rows.append(r)
                    # Append once per fit: avoid rewriting thousands of existing rows for every completion.
                    path = self.root/'fits.tsv'
                    fields = ('stage', 'index', 'smooth', 'candidate', 'seed', 'pliter', 'thorough', 'threads', 'status', 'objective', 'score', 'seconds', 'negative_returns', 'reason', 'fit_id')
                    with path.open('a', newline='') as handle:
                        writer = csv.DictWriter(handle, fieldnames=fields, delimiter='\t')
                        if handle.tell() == 0:
                            writer.writeheader()
                        writer.writerow({k: '-'.join(map(str, r[k])) if k == 'candidate' else r.get(k) for k in fields})
                    log(f'{label}: {len(results)}/{len(jobs)} complete ({sum(x["status"] == "failed" for x in results)} failed); '+stage_eta(started, len(results), len(jobs)))
        except BaseException:
            STOP.set()
            for future in pending:
                future.cancel()
            raise
        return results

    def assessments(self):
        table(self.root/'assessments.tsv', [dict(stage=r['stage'], index=r['index'], smoothing=r['smooth'],
              candidate='-'.join(map(str, r['candidate'])), seed=r['seed'], status=r['status'], assessment=r['assessment'],
              objective=r['objective'], score=r['score'], reason=r['reason'], fit_id=r['fit_id']) for r in self.rows])

    def consolidate(self, chosen):
        """Save compact results before removing any reproducible per-fit files."""
        directories = [self.directory(r) for r in self.rows]
        evaluations = self.root/'evaluations.jsonl'
        ages_output = self.root/'node_ages.tsv'
        nodes = None
        age_count = 0
        with evaluations.with_suffix('.jsonl.tmp').open('w') as records, ages_output.with_suffix('.tsv.tmp').open('w', newline='') as ages:
            writer = csv.writer(ages, delimiter='\t')
            for r, directory in zip(self.rows, directories):
                fit_id = r['fit_id']
                record = dict(r)
                # Preserve raw score strings even when parsing rejected NaN/Inf.
                logfile = directory/'run.log'
                logtext = logfile.read_text(errors='replace') if logfile.exists() else ''
                record['raw_cv_scores'] = SCORE.findall(logtext)
                validation = directory/'validation.log'
                record['validation_report'] = validation.read_text(errors='replace') if validation.exists() else ''
                if r['status'] != 'complete':
                    record['failure_log_tail'] = logtext[-4000:]
                records.write(json.dumps(record, allow_nan=False)+'\n')
                agefile = directory/'ages.tsv'
                cv = r['stage'] == 'cv'
                if r['status'] != 'complete' or cv:
                    continue
                with agefile.open() as handle:
                    values = {v['node']: v['age_ma'] for v in csv.DictReader(handle, delimiter='\t')}
                if nodes is None:
                    nodes = list(values)
                    writer.writerow(['fit_id']+['node_'+n for n in nodes])
                if set(values) != set(nodes) or any(not math.isfinite(float(v)) for v in values.values()):
                    raise RuntimeError('Inconsistent node ages; working files retained')
                writer.writerow([fit_id]+[values[n] for n in nodes]); age_count += 1
        os.replace(evaluations.with_suffix('.jsonl.tmp'), evaluations)
        os.replace(ages_output.with_suffix('.tsv.tmp'), ages_output)
        for source, target in [('fit.config', 'selected_fit.config'), ('validation.log', 'selected_validation.log')]:
            shutil.copyfile(self.directory(chosen)/source, self.root/target)
        report = dict(evaluations=len(self.rows), age_vectors=age_count, internal_nodes=len(nodes or []),
                      evaluations_sha256=digest(evaluations), node_ages_sha256=digest(ages_output),
                      keep_work=self.a.keep_work, status='consolidated')
        save(self.root/'retention.json', report)
        if not self.a.keep_work:
            # Only directories belonging to this run's recorded evaluations are removed.
            for directory in directories:
                shutil.rmtree(directory)
            for parent in sorted({d.parent for d in directories}, key=str):
                if parent.exists() and not any(parent.iterdir()):
                    parent.rmdir()
            for stage in sorted({d.parent.parent for d in directories}, key=str):
                if stage != self.root and stage.exists() and not any(stage.iterdir()):
                    stage.rmdir()
            report['status'] = 'cleaned'
            save(self.root/'retention.json', report)
        log(f'Results consolidated: {len(self.rows)} evaluations, {age_count} node-age vectors; '+
            ('working files retained (--keep-work)' if self.a.keep_work else 'per-fit working directories removed'))
        return report

    def compare(self, before, after, label):
        def ages(r):
            with (self.directory(r)/'ages.tsv').open() as handle:
                return {v['node']: float(v['age_ma']) for v in csv.DictReader(handle, delimiter='\t')}
        a, b = ages(before), ages(after)
        if a.keys() != b.keys():
            raise RuntimeError('Age comparison has inconsistent nodes')
        rows = [dict(node=n, before_ma=a[n], after_ma=b[n], delta_ma=b[n]-a[n]) for n in a]
        table(self.root/(label+'_ages.tsv'), rows)
        d = [abs(v['delta_ma']) for v in rows]
        report = dict(before_objective=before['objective'], after_objective=after['objective'],
                      objective_improvement_percent=100*(before['objective']-after['objective'])/max(abs(before['objective']), 1e-12),
                      median_age_change_ma=statistics.median(d), max_age_change_ma=max(d),
                      before_fit_id=before['fit_id'], after_fit_id=after['fit_id'])
        save(self.root/(label+'.json'), report)
        log(f'{label}: objective improvement={report["objective_improvement_percent"]:.6g}%; maximum age change={max(d):.6g} Ma')

    def graphics(self):
        try:
            checked([self.rscript, str(HERE/'treepl_benchmark_plot.R'), str(self.root)], self.root/'plotting.log')
        except (RuntimeError, OSError) as error:
            if STOP.is_set():
                raise
            log(f'WARNING: graphics failed; numerical work continues. {error}')

    def pipeline(self):
        a = self.a
        save(self.root/'parallelism.json', dict(pl=dict(jobs=a.jobs, threads=a.threads),
             cv=dict(jobs=a.cv_jobs, threads=a.cv_threads)))
        with futures.ThreadPoolExecutor(max_workers=a.jobs) as pool:
            pairs = sorted({c[:2] for c in a.candidates})
            nomination_seeds = a.seeds[:2]
            screen = self.batch(pool, [self.job('screen', i, pair+(0, 0), seed, a.pliter)
                for i in range(len(a.smoothing)) for pair in pairs for seed in nomination_seeds], 'Optimizer nomination')
            nominees, nomination_rows = {}, []
            for i, smooth in enumerate(a.smoothing):
                selected_pairs = set()
                for seed in nomination_seeds:
                    valid = [r for r in screen if r['index'] == i and r['seed'] == seed and r['status'] == 'complete']
                    ranked = sorted(valid, key=lambda r: (r['objective'], r['seconds'], r['candidate']))
                    for rank, r in enumerate(ranked, 1):
                        nominated = rank <= 3
                        if nominated:
                            selected_pairs.add(tuple(r['candidate'][:2]))
                        nomination_rows.append(dict(smoothing=smooth, seed=seed, pair='/'.join(map(str,r['candidate'][:2])),
                            rank=rank, objective=r['objective'], seconds=r['seconds'], nominated=nominated))
                nominees[i] = [c for c in a.candidates if c[:2] in selected_pairs]
                log(f'Optimizer nominations at smooth={smooth:g}: {len(selected_pairs)} pairs; '+
                    ', '.join('/'.join(map(str,c)) for c in sorted(selected_pairs)))
            table(self.root/'optimizer_nominations.tsv', nomination_rows)
            save(self.root/'optimizer_shortlists.json', nominees)
            existing = {(r['index'], tuple(r['candidate']), r['seed']) for r in screen}
            additional = [self.job('screen', i, c, seed, a.pliter)
                for i, candidates in nominees.items() for c in candidates for seed in a.seeds
                if (i, c, seed) not in existing]
            log(f'Optimizer confirmation: {len(additional)} new fits; matching nomination evaluations reused')
            screen += self.batch(pool, additional, 'Optimizer confirmation')
            for r in screen:
                r['assessment'] = 'nomination_only' if r['status'] == 'complete' else 'failed'
            selections, summaries, kept_by_group = {}, [], {}
            for i, smooth in enumerate(a.smoothing):
                local = []
                for c in nominees[i]:
                    rr = [r for r in screen if r['index'] == i and tuple(r['candidate']) == c]
                    kept, stats = assess(rr, 'objective', len(a.seeds), a.outlier_factor)
                    kept_by_group[i, c] = kept
                    values = [r['objective'] for r in kept]
                    row = dict(index=i, smoothing=smooth, candidate='-'.join(map(str, c)), **stats,
                               median=statistics.median(values) if values else None, worst=max(values) if values else None,
                               best=min(values) if values else None, seconds=statistics.median(r['seconds'] for r in kept) if kept else None,
                               selected=False)
                    summaries.append(row); local.append(row)
                selected = choose_optimizer(local)
                if selected:
                    selected['selected'] = True
                    c = tuple(map(int, selected['candidate'].split('-')))
                    winner = min(kept_by_group[i, c], key=lambda r: (r['objective'], r['seed']))
                    selections[i] = dict(candidate=c, best_fit=winner)
                    log(f'Optimizer selected at smooth={smooth:g}: {c}; median={selected["median"]:g}, usable seeds={selected["retained"]}/{len(a.seeds)}')
                else:
                    log(f'UNUSABLE smoothing={smooth:g}: no optimizer has a strict majority of usable seeds')
            table(self.root/'optimizer_summary.tsv', summaries)
            save(self.root/'optimizer_selections.json', selections)
            self.assessments(); self.graphics()
            if not selections:
                raise RuntimeError('No smoothing value has a usable optimizer configuration')
            with futures.ThreadPoolExecutor(max_workers=a.cv_jobs) as cv_pool:
                cv = self.batch(cv_pool, [self.job('cv', i, selected['candidate'], seed, a.pliter)
                    for i, selected in selections.items() for seed in a.seeds], 'Single-value CV')
            points = []
            for i, smooth in enumerate(a.smoothing):
                rr = [r for r in cv if r['index'] == i]
                if rr:
                    kept, stats = assess(rr, 'score', len(a.seeds), a.outlier_factor)
                else:
                    kept, stats = [], dict(requested=len(a.seeds), valid=0, retained=0, outliers=0, failures=0,
                                          filter_median=None, filter_enabled=False, usable=False)
                values = [r['score'] for r in kept]
                points.append(dict(index=i, smoothing=smooth, **stats, median=statistics.median(values) if values else None,
                    minimum=min(values) if values else None, maximum=max(values) if values else None,
                    candidate='-'.join(map(str, selections[i]['candidate'])) if i in selections else '', selected=False))
            usable = [r for r in points if r['usable']]
            chosen = min(usable, key=lambda r: (r['median'], -r['smoothing'])) if usable else None
            if chosen:
                chosen['selected'] = True
            table(self.root/'cv_summary.tsv', points)
            table(self.root/'cv_scores.tsv', [dict(smoothing=r['smooth'], seed=r['seed'], score=r['score'],
                 candidate='-'.join(map(str, r['candidate'])), status=r['status'], assessment=r['assessment'], reason=r['reason']) for r in cv])
            self.assessments(); self.graphics()
            if chosen is None:
                raise RuntimeError('No smoothing value has a strict majority of usable CV seeds')
            i = chosen['index']
            boundary = i in (0, len(a.smoothing)-1)
            save(self.root/'cv_selection.json', dict(smooth=chosen['smoothing'], median=chosen['median'], seeds=a.seeds,
                 candidate=selections[i]['candidate'], boundary_minimum=boundary,
                 incomplete_grid=any(not r['usable'] for r in points), points=points))
            log(f'Selected smoothing={chosen["smoothing"]:g}; median CV={chosen["median"]:g}')
            if boundary:
                log('NOTE: winner is at a requested grid boundary; continuing without expansion')
            if any(not r['usable'] for r in points):
                log('NOTE: selection excludes unusable grid points; inspect cv_summary.tsv')
            initial = selections[i]['best_fit']
            c = tuple(initial['candidate'])
            checks = self.batch(pool, [self.job('final_check', i, c, seed, a.final_pliter, thorough)
                for thorough in (False, True) for seed in a.seeds], 'Final seeds and thorough comparison')
            eligible = [initial] + [r for r in checks if r['status'] == 'complete']
            for r in checks:
                if r['status'] == 'complete':
                    self.compare(initial, r, f'final_seed_{r["seed"]}_thorough_{int(r["thorough"])}')
            valid_checks = [r for r in checks if r['status'] == 'complete']
            if valid_checks:
                best_check = min(valid_checks, key=lambda r: (r['objective'], r['thorough'], r['seed']))
                self.compare(initial, best_check, 'final_iteration_check')
            provisional = min(eligible, key=lambda r: (r['objective'], -r['pliter'], r['thorough'], r['seed']))
            standalone = self.batch(pool, [self.job('standalone', i, c, provisional['seed'], provisional['pliter'],
                                                   provisional['thorough'])], 'Standalone confirmation')[0]
            if standalone['status'] == 'complete':
                eligible.append(standalone); self.compare(provisional, standalone, 'standalone_check')
            else:
                log('WARNING: standalone confirmation failed; retaining a previously validated fit')
            winner = min(eligible, key=lambda r: (r['objective'], -r['pliter'], r['thorough'], r['seed']))
            for r in (*checks, standalone):
                r['assessment'] = 'retained' if r['status'] == 'complete' else 'failed'
            table(self.root/'final_summary.tsv', [dict(stage=r['stage'], seed=r['seed'], pliter=r['pliter'], thorough=r['thorough'],
                  objective=r['objective'], status=r['status'], selected=r is winner, fit_id=r['fit_id']) for r in (initial, *checks, standalone)])
            save(self.root/'final_selection.json', dict(selection=winner, standalone_valid=standalone['status'] == 'complete'))
            self.assessments(); self.graphics()
            return winner


def main():
    global LOG_PATH, PUBLICATION_COMPLETE
    args = parse_args()
    config = args.config.resolve(strict=True)
    generated = config.parent/'generated'
    if generated.is_symlink():
        raise ValueError('Refusing to clear a symlinked generated directory')
    root = generated/'treepl_benchmark'
    lockpath = config.parent/'.treepl.lock'
    inherited = os.environ.get('VGP_TREEPL_LOCK_FD')
    lock = os.fdopen(os.dup(int(inherited)), 'w') if inherited else lockpath.open('w')
    with lock:
        if inherited and os.fstat(lock.fileno()).st_ino != lockpath.stat().st_ino:
            raise RuntimeError('Launcher lock does not match this analysis')
        try:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another run owns this analysis; its outputs were not deleted')
        binary = shutil.which('treePL'); rscript = shutil.which('Rscript')
        if not binary or not rscript:
            raise RuntimeError('treePL and Rscript must be on PATH')
        binary = str(Path(binary).resolve())
        original = config.read_text()
        options = settings(original)
        for name in ('treefile','outfile','numsites','smooth','pliter'):
            if name not in options or options[name] is True:
                raise ValueError(f'Missing {name}')
        if any(k in options for k in ('prime','thorough','cv','randomcv','inr8s','ind8s','log_pen')):
            raise ValueError('Remove active run modes/log_pen from input; use --thorough for screening/CV; final fits always compare both modes')
        if int(options['numsites'])<1:
            raise ValueError('numsites must be positive')
        tree = (config.parent/options['treefile']).resolve(strict=True)
        if any(ch.isspace() for ch in str(tree)):
            raise ValueError('treePL requires an input tree path without whitespace')
        master = args.master.resolve(strict=True)
        calibration_check(original,master,config.stem)
        parameters = {k:v for k,v in vars(args).items() if k not in ('config','master','dry_run')}
        identity = dict(config=str(config),master=str(master), tree=str(tree),tree_sha256=digest(tree), master_sha256=digest(master),
                        binary=binary,binary_sha256=digest(binary),parameters=parameters,
                        code_sha256={p.name:digest(p) for p in (Path(__file__),HERE/'treepl_validate.R',HERE/'treepl_benchmark_plot.R')})
        output = (config.parent/options['outfile']).resolve()
        if not output.is_relative_to(generated.resolve()):
            raise ValueError('outfile must be under this analysis generated/ directory')
        if any(path.is_relative_to(generated.resolve()) for path in (config,tree,master)):
            raise ValueError('Input config, tree, and master must be outside deletable generated/')
        # Validate in temporary space: --dry-run and preflight failures preserve old results.
        with tempfile.TemporaryDirectory(prefix='treepl-preflight-') as temporary:
            temp = Path(temporary)
            (temp/'input.config').write_text(original)
            try:
                checked([rscript,str(HERE/'treepl_validate.R'),str(tree),str(temp/'input.config'),'-',str(temp/'ages.tsv')],temp/'validation.log')
            except RuntimeError as error:
                raise RuntimeError('Input validation failed: '+(temp/'validation.log').read_text().strip()) from error
            validation = (temp/'validation.log').read_text()
        pair_count = len({c[:2] for c in args.candidates})
        seed_count = min(2, len(args.seeds))
        details_count = len({c[2:] for c in args.candidates})
        reuse = seed_count if any(c[2:] == (0, 0) for c in args.candidates) else 0
        maximum = (pair_count*seed_count + min(pair_count, 3*seed_count)*(details_count*len(args.seeds)-reuse))*len(args.smoothing)
        log(f'Plan: {pair_count} pairs × {seed_count} nomination seeds per smoothing, then up to {min(pair_count, 3*seed_count)} pairs × {details_count} detail settings × {len(args.seeds)} seeds; at most {maximum} optimizer fits including reused nominations; up to {len(args.seeds)*len(args.smoothing)} CV jobs; {2*len(args.seeds)+1} final fits')
        log(f'Smoothing grid: {args.smoothing}; shared seeds: {args.seeds}; pliter={args.pliter}, cviter={args.cviter}, final-pliter={args.final_pliter}; thorough={args.thorough}; final fits compare thorough off/on')
        log(f'Parallelism: PL {args.jobs} jobs x {args.threads} threads; CV {args.cv_jobs} jobs x {args.cv_threads} threads (fixed settings; no timing pilot)')
        if args.dry_run:
            log('Preflight passed. No fits started or existing outputs changed.')
            return
        if generated.exists():
            shutil.rmtree(generated)
        root.mkdir(parents=True)
        LOG_PATH = generated/'benchmark.log'
        log(f'Fresh run: cleared previous outputs; results will be saved under {generated}')
        if max(args.jobs*args.threads, args.cv_jobs*args.cv_threads)>(os.cpu_count() or 1):
            log('Warning: requested worker threads exceed logical CPU count')
        atomic(root/'input.config',original)
        atomic(root/'input_validation.log',validation)
        atomic(generated/'final_run_status.txt','status=running\nstage=benchmark\n')
        manifest_path = root/'manifest.json'
        manifest = dict(identity=identity,original_config_sha256=digest(config),status='running')
        save(manifest_path,manifest)
        benchmark = Benchmark(args,root,original,tree,binary,rscript)
        try:
            chosen = benchmark.pipeline()
            candidate = chosen['candidate']
            updates = dict(smooth=f'{chosen["smooth"]:.17g}',pliter=chosen['pliter'],seed=chosen['seed'],
                           nthreads=chosen['threads'],cviter=args.cviter,opt=candidate[0],optad=candidate[1])
            final = config_text(original,updates,dict(moredetail=bool(candidate[2]),moredetailad=bool(candidate[3]),thorough=False))
            atomic(root/'final.config',final)
            if digest(config)!=manifest['original_config_sha256']:
                raise RuntimeError('Analysis config edited during run; refusing to overwrite')
            if digest(tree)!=identity['tree_sha256'] or digest(master)!=identity['master_sha256'] or digest(binary)!=identity['binary_sha256']:
                raise RuntimeError('Tree, master, or executable changed during run; refusing publication')
            calibration_check(final,master,config.stem)
            manifest.update(status='validated',published_config_sha256=digest(root/'final.config'),selection=chosen,
                       thorough_requested=args.thorough,selected_thorough=chosen['thorough'],
                       parallelism=json.loads((root/'parallelism.json').read_text()))
            save(manifest_path,manifest)
            output.parent.mkdir(parents=True,exist_ok=True)
            temp = output.with_name(output.name+'.tmp')
            shutil.copyfile(benchmark.directory(chosen)/'result.tre',temp)
            os.replace(temp,output)
            atomic(config,final)
            with master.open() as handle:
                reader = csv.DictReader(handle); fields = reader.fieldnames
                subset = [r for r in reader if r['node_'+config.stem.replace('.', '_')].strip()]
            with (generated/(config.stem+'.calibrations.csv')).open('w', newline='') as handle:
                writer = csv.DictWriter(handle, fieldnames=fields); writer.writeheader(); writer.writerows(subset)
            PUBLICATION_COMPLETE = True
            manifest.update(status='published', output_sha256=digest(output), retention=dict(status='pending'))
            save(manifest_path, manifest)
            atomic(generated/'final_run_status.txt','status=published\nstage=cleanup\n')
            try:
                manifest['retention'] = benchmark.consolidate(chosen)
            except Exception as error:
                manifest['retention'] = dict(status='incomplete', reason=str(error))
                log(f'WARNING: results published, but consolidation/cleanup was incomplete: {error}')
            manifest.update(status='complete',output_sha256=digest(output)); save(manifest_path,manifest)
            atomic(generated/'final_run_status.txt',f'status=complete\nstage=benchmark\ncleanup={manifest["retention"]["status"]}\n')
            log(f'COMPLETE: selected seed={chosen["seed"]}, smooth={chosen["smooth"]:g}, pliter={chosen["pliter"]}; config and validated dated tree published')
        except BaseException as error:
            manifest.update(status='published' if PUBLICATION_COMPLETE else 'stopped', reason=str(error) or 'interrupted'); save(manifest_path,manifest)
            raise


if __name__=='__main__':
    def interrupted(signum, frame):
        STOP.set()
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM,interrupted)
    try:
        main()
    except (Exception,KeyboardInterrupt) as error:
        STOP.set()
        log(f'Benchmark stopped: {error or "interrupted"}')
        if LOG_PATH is not None:
            atomic(LOG_PATH.parent/'final_run_status.txt',
                   'status=published\nstage=cleanup\ncleanup=interrupted\n' if PUBLICATION_COMPLETE else 'status=failed\nstage=benchmark\n')
        sys.exit(1)
