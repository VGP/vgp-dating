#!/usr/bin/env python3
"""Benchmark both trees and update their configs and figures."""
import argparse
import csv
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

from treepl_benchmark import VALIDATE_R

BASE = Path(__file__).resolve().parent
REPO = BASE.parent.parent
TREES = {'ASTRAL': 'astralpro.l6p1', 'ROADIES': 'roadies_v1.1.16b'}


def config_path(tree):
    stem = tree + ('.perspecies' if tree == 'astralpro.l6p1' else '')
    return BASE / tree / (stem + '.round2.config')


def run(*args):
    display = ['<validation code>' if isinstance(x, str) and '\n' in x else str(x) for x in args]
    print('+', ' '.join(display), flush=True)
    subprocess.run(list(map(str, args)), check=True, cwd=REPO)


def option(text, name):
    matches = re.findall(r'^\s*' + re.escape(name) + r'\s*=\s*(\S+)', text, re.M)
    if len(matches) != 1:
        raise ValueError(f'Expected one {name} in config')
    return matches[0]


def format_config(text, name):
    """Keep all active settings together above the unchanged calibrations."""
    controls, body = {}, []
    for line in text.splitlines():
        match = re.match(r'^\s*([A-Za-z_][A-Za-z_0-9]*)\s*(?:=|$)', line)
        if match and match.group(1) not in ('mrca', 'min', 'max'):
            key = match.group(1)
            if key in controls: raise ValueError(f'Duplicate setting: {key}')
            controls[key] = line.strip()
        elif line.strip() != '# Run from this directory.' and not line.startswith(('# treePL defaults:', '# Detail flags off:', '# Fitting flags off:')) and not re.match(r'^# (ASTRAL|ROADIES) treePL —', line):
            body.append(line.rstrip())
    order = ['treefile', 'outfile', 'seed', 'nthreads', 'numsites', 'smooth',
             'opt', 'optad', 'optcvad', 'moredetail', 'moredetailad', 'moredetailcvad',
             'lfiter', 'pliter', 'cviter', 'lfsimaniter', 'ftol', 'xtol']
    for key, default in (('lfiter', '3'), ('xtol', '-1')):
        if key in controls and option(controls[key], key) == default:
            del controls[key]
    lines = [f'# {name} treePL — run from this directory']
    for key in order + sorted(set(controls) - set(order)):
        if key in controls: lines.append(controls[key])
    for label, flags in (
        ('Detail', ('moredetail', 'moredetailad', 'moredetailcvad')),
        ('Fitting', ('thorough', 'calcgrad', 'log_pen', 'collapse', 'set1')),
    ):
        off = [f for f in flags if f not in controls]
        if off: lines.append(f'# {label} flags off: ' + ', '.join(off))
    while body and not body[0].strip(): body.pop(0)
    text = '\n'.join(lines + [''] + body).rstrip() + '\n'
    return re.sub(r'(?m)^(##[^\n]*)\n\n*', r'\1\n\n', text)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(name, tree, results, stage, treepl):
    source = config_path(tree)
    original = source.read_text()
    settings = json.loads((results / 'settings.json').read_text())
    status = json.loads((results / 'status.json').read_text())
    final = json.loads((results / 'final-checks' / 'summary.json').read_text())
    if status['phase'] != 'Complete' or final.get('final_tree_check') != 'passed with corrected treePL':
        raise ValueError(f'{name}: benchmark or final tree check is incomplete')
    if settings['binary_sha256'] != digest(treepl):
        raise ValueError(f'{name}: results do not match the corrected treePL executable')
    treepath = (source.parent / option(original, 'treefile')).resolve()
    if settings['config_sha256'] != digest(source) or settings['tree_sha256'] != digest(treepath):
        raise ValueError(f'{name}: results do not match current input config and tree')
    recommended = (results / 'recommended.config').read_text()
    for key in ('treefile', 'outfile'):
        value = option(original, key)
        recommended = re.sub(r'^\s*' + key + r'\s*=.*$', lambda _: key + ' = ' + value,
                             recommended, count=1, flags=re.M)
    recommended = format_config(recommended, name)
    dest = stage / tree
    dest.mkdir(parents=True)
    run('Rscript', '-e', VALIDATE_R, treepath, results / 'dated.tre', source)
    (dest / source.name).write_text(recommended)
    shutil.copyfile(results / 'dated.tre', dest / (tree + '.treePL.tre'))
    shutil.copyfile(results / 'summary.png', dest / 'optimization.png')
    points = list(csv.DictReader((results / 'points.csv').open()))
    attempts = json.loads((results / 'attempts.json').read_text())
    n = settings['replicates']
    with (dest / 'optimization.tsv').open('w', newline='') as f:
        writer = csv.writer(f, delimiter='\t', lineterminator='\n')
        writer.writerow(['smoothing', 'accepted', 'discarded', 'median_cv', 'selected'] + [f'cv_{i+1}' for i in range(n)])
        for point in sorted(points, key=lambda p: float(p['x']), reverse=True):
            x = float(point['x'])
            rows = [r for r in attempts if r['x'] == x]
            scores = {r['replicate']: r['score'] for r in rows if r['status'] == 'complete'}
            writer.writerow([10**x, len(scores), sum(r['status'] != 'complete' for r in rows),
                             point['median'], 10**x == final['smoothing']] + [scores.get(i, '') for i in range(n)])
    run('Rscript', BASE / 'plot_treepl.R', tree, dest)
    return source, dest


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--treepl', type=Path, required=True, help='corrected treePL executable')
    p.add_argument('--workers', type=int, default=max(1, (os.cpu_count() or 1)-1))
    p.add_argument('--results-root', type=Path, help='reuse completed ASTRAL and ROADIES runs')
    a = p.parse_args()
    if a.workers < 1: p.error('workers must be positive')
    treepl = a.treepl.resolve()
    if not treepl.is_file(): p.error('corrected treePL executable not found')
    run('Rscript', BASE / 'calibration_config.R', '--update')
    root = a.results_root.resolve() if a.results_root else REPO / '.cache' / ('treepl-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    if not a.results_root:
        for name, tree in TREES.items():
            run(sys.executable, BASE / 'treepl_benchmark.py', config_path(tree),
                '--treepl', treepl, '--output', root / name, '--workers', a.workers)
    (REPO / '.cache').mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='treepl-update-', dir=REPO / '.cache') as tmp:
        staged = [prepare(name, tree, root / name, Path(tmp), treepl) for name, tree in TREES.items()]
        for source, dest in staged:
            generated = source.parent / 'generated'
            generated.mkdir(exist_ok=True)
            for file in dest.iterdir():
                shutil.copyfile(file, source if file.suffix == '.config' else generated / file.name)
            print('Updated', source.parent, flush=True)
    print('Results:', root, flush=True)


if __name__ == '__main__':
    main()
