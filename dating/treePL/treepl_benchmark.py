#!/usr/bin/env python3
"""Select fast treePL settings, sweep smoothing, and export the final fit."""
# R snippets are embedded for plotting and validation.
PLOT_R = r"""
library(ggplot2)
library(jsonlite)
args <- commandArgs(trailingOnly=TRUE); root <- args[1]
d <- read.csv(file.path(root,'curve.csv')); p <- read.csv(file.path(root,'points.csv'))
d <- d[d$status=='complete' & is.finite(d$score) & d$score>0,,drop=FALSE]
boxes <- if (nrow(d)) do.call(rbind,lapply(split(d,d$x),function(z) {
  b <- boxplot.stats(z$score)$stats
  data.frame(x=z$x[1],ymin=b[1],lower=b[2],middle=b[3],upper=b[4],ymax=b[5])
})) else data.frame(x=numeric(),ymin=numeric(),lower=numeric(),middle=numeric(),upper=numeric(),ymax=numeric())
g <- ggplot() +
  geom_boxplot(data=boxes,aes(x=x,ymin=ymin,lower=lower,middle=middle,upper=upper,ymax=ymax,group=x),
               stat='identity',width=.22,fill='#eeeeee',colour='#777777',linewidth=.3,na.rm=TRUE) +
  geom_point(data=d,aes(x=x,y=score),position=position_jitter(width=.06,height=0,seed=17),
             colour='#888888',size=.8,alpha=.75,na.rm=TRUE) +
  geom_line(data=p,aes(x=x,y=median),colour='#404040',linewidth=.6,na.rm=TRUE) +
  scale_x_continuous(limits=c(-6.15,4.15),breaks=seq(-6,4,2),labels=function(x) paste0('1e',x)) +
  scale_y_log10(labels=scales::label_number()) +
  labs(title='Smoothing CV',
       x='Smoothing (log scale)',y='CV score (log scale)') +
  theme_classic(base_size=10) + theme(plot.title=element_text(face='bold',size=11),
    axis.line=element_line(linewidth=.3),axis.ticks=element_line(linewidth=.3))
tmp <- file.path(root,paste0('summary.',Sys.getpid(),'.tmp.png'))
ggsave(tmp,g,width=6.5,height=4,dpi=200,bg='white')
file.rename(tmp,file.path(root,'summary.png'))
"""
VALIDATE_R = r"""
suppressPackageStartupMessages(library(ape))
args <- commandArgs(trailingOnly=TRUE)
ref <- read.tree(args[1]); tree <- read.tree(args[2])
if (!inherits(tree,'phylo') || is.null(tree$edge.length) || any(!is.finite(tree$edge.length)) || any(tree$edge.length<0))
  stop('Expected finite nonnegative branch lengths')
if (!isTRUE(all.equal.phylo(ref,tree,use.edge.length=FALSE,use.tip.label=TRUE))) stop('Topology or taxa changed')
depth <- node.depth.edgelength(tree)
if (diff(range(depth[seq_len(Ntip(tree))]))>.001) stop('Dated tree is not ultrametric')
ages <- max(depth[seq_len(Ntip(tree))])-depth
entries <- lapply(trimws(sub('#.*$','',readLines(args[3]))),function(x) strsplit(trimws(gsub('=',' ',x,fixed=TRUE)),'[[:space:]]+')[[1]])
for (pair in Filter(function(x)length(x)>0 && x[1]=='mrca',entries)) {
  node <- getMRCA(tree,pair[-(1:2)])
  if (is.null(node) || is.na(node)) stop('Calibration taxa not found: ',pair[2])
  for (key in c('min','max')) {
    bound <- Filter(function(x)length(x)>2 && x[1]==key && x[2]==pair[2],entries)
    if (!length(bound)) next
    value <- as.numeric(bound[[1]][3])
    if ((key=='min' && ages[node]<value-.001) || (key=='max' && ages[node]>value+.001)) stop('Calibration violation: ',pair[2])
  }
}
cat('Final tree validation passed.\n')
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import statistics
import subprocess
import sys
import threading
import time

CONTROL_KEYS={'prime','cv','randomcv','cvstart','cvstop','cvmultstep','cvoutfile','thorough',
    'randomcviter','randomcvsamp','cvseed','plsimaniter','cvsimaniter','calcgrad','siman',
    'maxoptimiters','paramverbose','mapspace','startstate','otherstate','stateout','cvlocal','polish'}
SCORE=re.compile(r'^chisq: \(([^)]+)\)\s*(\S+)',re.M)
OBJECTIVE=re.compile(r'^after opt calc:\s*(\S+)',re.M)

def parse_cv(log,saved,smoothing):
    printed=list(SCORE.finditer(log))
    matches=[(i,m) for i,m in enumerate(printed) if math.isclose(float(m[1]),smoothing,rel_tol=1e-5)]
    written=[(float(sm),float(score)) for sm,score in SCORE.findall(saved)
             if math.isclose(float(sm),smoothing,rel_tol=1e-5)]
    if len(matches)!=1 or len(written)!=1 or 'conducting RANDOM SUBSAMPLE' not in log:
        raise ValueError('Missing or unexpected randomCV output')
    i,m=matches[0];score,wscore=float(m[2]),written[0][1]
    if not all(math.isfinite(v) and v>=0 for v in (score,wscore)) or not math.isclose(score,wscore,rel_tol=5e-6):
        raise ValueError('Nonfinite, negative, or inconsistent CV score')
    start=printed[i-1].end() if i else 0
    folds=[float(x) for x in re.findall(r'^post opt cv check:\s*(\S+)',log[start:m.start()],re.M)]
    samples=re.findall(r'^cv sample (\d+):([^\n]*)',log,re.M)
    if len(folds)!=10 or not all(math.isfinite(x) for x in folds):raise ValueError('Expected ten finite CV training objectives')
    if [int(i) for i,_ in samples]!=list(range(10)):raise ValueError('Missing or unordered CV sample records')
    masks=[sorted(taxa.split()) for _,taxa in samples]
    if any(not m or len(set(m))!=len(m) for m in masks):raise ValueError('Empty or duplicate CV sample')
    return score,folds,masks

ACTIVE = set()
LOCK = threading.Lock()
CONTROL = CONTROL_KEYS | {'treefile','outfile','seed','nthreads','smooth','opt','optad','optcvad',
    'moredetail','moredetailad','moredetailcvad','pliter','cviter','lfsimaniter','ftol'}


def atomic_json(path, value):
    temp = path.with_suffix('.tmp')
    temp.write_text(json.dumps(value, indent=2, allow_nan=False)+'\n')
    temp.replace(path)


def fit(job):
    folder = Path(job['folder']); folder.mkdir(parents=True)
    clean = '\n'.join(line for line in job['config'].splitlines()
        if line.split('#',1)[0].partition('=')[0].strip() not in CONTROL)
    values = dict(treefile=job['tree'], outfile='result.tre', seed=job['seed'], nthreads=1,
        smooth=f"{10**job['x']:.17g}", stateout='state', cvseed=job['cvseed'],
        cvstart=f"{10**job['x']:.17g}", cvstop=f"{10**job['x']*(1-1e-9):.17g}",
        cvmultstep=.1, cvoutfile='cv.out')
    if job['start']:
        values['startstate'] = job['start']
    values.update({k:v for k,v in job['profile'].items() if not k.startswith('moredetail')})
    lines = [clean] + [f'{k} = {v}' for k,v in values.items()]
    lines += [k for k,v in job['profile'].items() if k.startswith('moredetail') and v]
    lines += ['cv','randomcv']
    (folder/'fit.config').write_text('\n'.join(lines)+'\n')
    started = time.monotonic(); stopped_after_cv = False
    with (folder/'run.log').open('w') as log:
        proc = subprocess.Popen([job['binary'],'fit.config'],cwd=folder,stdout=log,stderr=subprocess.STDOUT,
            env={**os.environ,'OMP_NUM_THREADS':'1','TREEPL_BENCH_STAGE':'normal'})
        with LOCK: ACTIVE.add(proc)
        try:
            while proc.poll() is None:
                path = folder/'cv.out'
                saved = path.read_text(errors='replace') if path.exists() else ''
                if SCORE.search(saved):
                    text = (folder/'run.log').read_text(errors='replace')
                    if len(re.findall(r'^cv prediction: \d+ \S+',text,re.M)) == 10:
                        stopped_after_cv = True; proc.terminate(); break
                time.sleep(.1)
            proc.wait()
        finally:
            if proc.poll() is None: proc.terminate(); proc.wait()
            with LOCK: ACTIVE.discard(proc)
    text = (folder/'run.log').read_text(errors='replace')
    saved = (folder/'cv.out').read_text(errors='replace') if (folder/'cv.out').exists() else ''
    score = None; folds = []; masks = []; objective = None
    try:
        score, folds, masks = parse_cv(text,saved,10**job['x'])
        vals = OBJECTIVE.findall(text)
        objective = float(vals[-1]) if vals else None
        predictions = re.findall(r'^cv prediction: (\d+) (\S+)$',text,re.M)
        good = ((proc.returncode == 0 or stopped_after_cv) and objective is not None and math.isfinite(objective)
            and score <= 1e12 and [int(i) for i,_ in predictions] == list(range(10))
            and math.isclose(score,sum(float(v) for _,v in predictions),rel_tol=1e-10,abs_tol=1e-8)
            and (folder/'state.0').exists())
    except (ValueError, OverflowError):
        good = False
    return dict(x=job['x'],replicate=job['replicate'],attempt=job['attempt'],profile=job['profile'],
        status='complete' if good else 'discarded',score=score if score is not None and math.isfinite(score) else None,
        objective=objective if objective is not None and math.isfinite(objective) else None,
        folds=[v if math.isfinite(v) else None for v in folds], masks=masks,
        optimizer_evaluation_limits=len(re.findall(r'^result:\s*5\s*$',text,re.M)),
        state=str(folder/'state.0'), seconds=time.monotonic()-started, folder=str(folder))


def dips(points):
    ordered = sorted(points)
    found = []
    for left,mid,right in zip(ordered,ordered[1:],ordered[2:]):
        a,b,c = (points[x]['median'] for x in (left,mid,right))
        if b < a and b < c:
            found.append(dict(x=mid,score=b,strength=min(a-b,c-b),bracket=[left,right]))
    return sorted(found,key=lambda z:(-z['strength'],-z['x']))


class Sweep:
    def __init__(self,a):
        self.a=a; self.root=a.output.resolve(); self.root.mkdir(parents=True,exist_ok=False)
        self.work=self.root/'fits'; self.work.mkdir(); self.config=a.config.resolve().read_text()
        m=re.search(r'^\s*treefile\s*=\s*(\S+)',self.config,re.M)
        if not m: raise ValueError('Input config must specify treefile')
        self.tree=str((a.config.resolve().parent/m.group(1)).resolve())
        self.binary=str(a.treepl.resolve()); self.states={i:[] for i in range(max(4,a.replicates))}
        self.points={}; self.rows=[]; self.races=[]; self.calls=0; self.ranking=[]
        self.current=dict(opt=0,optad=0,optcvad=3,moredetail=0,moredetailad=0,moredetailcvad=0)
        self.phase='Starting'; self.started=time.monotonic(); self.status_lock=threading.Lock()

    def write(self, status_only=False):
        if not status_only:
            atomic_json(self.root/'attempts.json',self.rows)
            atomic_json(self.root/'races.json',self.races)
        atomic_json(self.root/'status.json',dict(phase=self.phase,elapsed_seconds=time.monotonic()-self.started,
            completed_values=sum(p['median'] is not None for p in self.points.values()),
            treepl_calls=self.calls,replicates=self.a.replicates,current_profile=self.current,
            optimizer_evaluation_limits=sum(r.get('optimizer_evaluation_limits',0) for r in
                {r['folder']:r for r in self.rows+self.races}.values())))
        if status_only: return
        with (self.root/'curve.csv').open('w',newline='') as f:
            w=csv.writer(f); w.writerow(['x','replicate','score','status'])
            w.writerows([[r['x'],r['replicate'],r['score'],r['status']] for r in self.rows])
        with (self.root/'points.csv').open('w',newline='') as f:
            w=csv.writer(f);w.writerow(['x','median']);w.writerows([[x,p['median']] for x,p in sorted(self.points.items())])
        try:
            plot=subprocess.run([shutil.which('Rscript') or 'Rscript','-e',PLOT_R,str(self.root)],
                                stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,check=False)
            if plot.returncode:
                print(f'Plot update failed (exit {plot.returncode}): {plot.stderr.strip()}',file=sys.stderr,flush=True)
        except OSError as error:
            print(f'Plot update failed: {error}',file=sys.stderr,flush=True)

    def count_final(self):
        with self.status_lock:
            self.calls += 1
            self.write(status_only=True)

    def job(self,x,rep,attempt,profile,label):
        sources=sorted(self.states[rep],key=lambda item:abs(item[0]-x))
        self.calls += 1
        return dict(x=x,replicate=rep,attempt=attempt,profile=profile.copy(), config=self.config,
            tree=self.tree,binary=self.binary, seed=self.a.seed+100030+rep+1009*attempt,
            cvseed=self.a.seed+100000+rep,start=sources[0][1] if sources else None,
            folder=str(self.work/f'x{x:+.5f}'/f'{label}-{self.calls}'))

    def screen(self):
        self.phase='Optimizer speed screen at smoothing 1'; self.write()
        profiles=[dict(opt=i,optad=i,optcvad=i,moredetail=0,moredetailad=0,moredetailcvad=0) for i in range(6)]
        jobs=[self.job(0.,rep,0,p,'screen') for p in profiles for rep in range(4)]
        with ThreadPoolExecutor(max_workers=self.a.workers) as pool:
            futures=[pool.submit(fit,j) for j in jobs]
            for future in as_completed(futures):
                row=future.result(); self.races.append(row); self.write()
                print(f"screen optimizer={row['profile']['opt']} replicate={row['replicate']+1} {row['status']} {row['seconds']:.1f}s",flush=True)
        valid={i:sorted((r for r in self.races if r['profile']['opt']==i and r['status']=='complete'),key=lambda r:r['replicate']) for i in range(6)}
        complete=[i for i in range(6) if len(valid[i])==4]
        if not complete: raise RuntimeError('No optimizer completed all four screening fits')
        for rep in range(4):
            groups=[next(r for r in valid[i] if r['replicate']==rep)['masks'] for i in complete]
            if any(g!=groups[0] for g in groups): raise RuntimeError('Screen used different CV groups')
        # Same existing numerical comparison as optimizer races: training objectives only.
        best=complete[0]
        def improvement(a,b):
            return statistics.median((u-v)/max(1,abs(u)) for ra,rb in zip(valid[a],valid[b])
                for u,v in zip([ra['objective']]+ra['folds'],[rb['objective']]+rb['folds']))
        for i in complete[1:]:
            if improvement(best,i)>1e-10: best=i
        comparable=[i for i in complete if improvement(i,best)<=1e-10]
        ordered=sorted(comparable,key=lambda i:statistics.median(r['seconds'] for r in valid[i]))
        ordered += sorted((i for i in complete if i not in comparable),key=lambda i:statistics.median(r['seconds'] for r in valid[i]))
        ordered += [i for i in range(6) if i not in ordered]
        self.ranking=[profiles[i] for i in ordered]; self.current=self.ranking[0].copy()
        atomic_json(self.root/'optimizer-screen.json',dict(ranking=ordered,comparable=comparable,results=self.races))
        print(f'Optimizer ranking: {ordered}; comparable to best training fit: {comparable}',flush=True)

    def evaluate(self,x,index):
        self.points[x]={'median':None}; self.phase=f'CV: {10**x:g}'; self.write()
        pending=set(range(self.a.replicates)); retries={r:0 for r in pending}; accepted={}
        while pending:
            jobs={r:self.job(x,r,retries[r],self.ranking[retries[r] % len(self.ranking)],'cv') for r in pending}
            pool=ThreadPoolExecutor(max_workers=self.a.workers)
            try:
                futures={pool.submit(fit,j):r for r,j in jobs.items()}
                for f in as_completed(futures):
                    rep=futures[f]; row=f.result(); self.rows.append(row)
                    if row['status']=='complete':
                        accepted[rep]=row['score']; self.states[rep].append((x,row['state']));pending.remove(rep)
                    else: retries[rep]+=1
                    print(f"x={x:g} replicate={rep+1} optimizer={row['profile']['opt']} {row['status']} score={row['score']} {row['seconds']:.1f}s",flush=True)
                    self.write()
            except BaseException:
                with LOCK:
                    for proc in list(ACTIVE): proc.terminate()
                raise
            finally: pool.shutdown(wait=True,cancel_futures=True)
        self.points[x]['median']=statistics.median(accepted.values()); self.write()

    def run(self):
        atomic_json(self.root/'settings.json',dict(replicates=self.a.replicates,workers=self.a.workers,seed=self.a.seed,
            first_sweep=list(range(4,-7,-1)),detail_flags='off during sweep; test at selected minimum', optimizer_selection='six profiles, four matched CV starts at smoothing 1; fastest tied training fit; ranked fallback',
            treepl_fitting_parameters='native defaults', retry_policy='no fixed limit',
            config_sha256=hashlib.sha256(self.a.config.resolve().read_bytes()).hexdigest(),
            tree_sha256=hashlib.sha256(Path(self.tree).read_bytes()).hexdigest(),
            binary_sha256=hashlib.sha256(Path(self.binary).read_bytes()).hexdigest()))
        self.write()
        self.screen()
        for i,x in enumerate(range(4,-7,-1)): self.evaluate(float(x),i)
        atomic_json(self.root/'dip-candidates.json',dict(all=dips(self.points)))
        self.phase='Final detail and seed checks'; self.write()
        run_final(self.root, self.a.config.resolve(), Path(self.binary), self.a.workers, self.count_final)
        self.phase='Complete'; self.write()


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('config',type=Path)
    p.add_argument('--treepl',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    p.add_argument('--workers',type=int,default=max(1,(os.cpu_count() or 1)-1));p.add_argument('--seed',type=int,default=20261102)
    p.add_argument('--replicates',type=int,default=12)
    a=p.parse_args()
    if a.workers<1 or a.replicates<1:p.error('workers and replicates must be positive')
    version=subprocess.run([str(a.treepl.resolve()),'--version'],capture_output=True,text=True)
    if 'vgp-optimizer-fixes-8' not in version.stdout:p.error('corrected treePL build required for the benchmark')
    if b'cv prediction: ' not in a.treepl.resolve().read_bytes():
        p.error('treePL is missing CV-prediction support; rebuild with dating/treePL/treepl.patch')
    signal.signal(signal.SIGTERM,lambda *_:(_ for _ in ()).throw(KeyboardInterrupt()))
    sweep=Sweep(a)
    try:sweep.run()
    except BaseException:
        with LOCK:
            for proc in list(ACTIVE): proc.terminate()
        sweep.phase='Stopped or failed';sweep.write();raise


def final_fit(job):
    folder=Path(job['folder']);folder.mkdir(parents=True)
    clean='\n'.join(line for line in job['config'].splitlines()
        if line.split('#',1)[0].partition('=')[0].strip() not in CONTROL)
    values=dict(treefile=job['tree'],outfile='result.tre',seed=job['seed'],nthreads=1,
                smooth=f"{10**job['x']:.17g}",stateout='state')
    if job.get('start'):
        values['startstate']=job['start']
    values.update({k:v for k,v in job['profile'].items() if not k.startswith('moredetail')})
    lines=[clean]+[f'{k} = {v}' for k,v in values.items()]
    lines += [k for k,v in job['profile'].items() if k.startswith('moredetail') and v]
    (folder/'fit.config').write_text('\n'.join(lines)+'\n')
    started=time.monotonic()
    with (folder/'run.log').open('w') as log:
        proc=subprocess.Popen([job['binary'],'fit.config'],cwd=folder,stdout=log,stderr=subprocess.STDOUT,
            env={**os.environ,'OMP_NUM_THREADS':'1','TREEPL_BENCH_STAGE':'normal'})
        with LOCK:ACTIVE.add(proc)
        try: proc.wait()
        finally:
            if proc.poll() is None:proc.terminate();proc.wait()
            with LOCK:ACTIVE.discard(proc)
    text=(folder/'run.log').read_text(errors='replace');vals=OBJECTIVE.findall(text)
    try:objective=float(vals[-1]) if vals else None
    except ValueError:objective=None
    good=(proc.returncode==0 and objective is not None and math.isfinite(objective)
          and (folder/'result.tre').exists() and (folder/'state').exists())
    return dict(seed=job['seed'],profile=job['profile'].copy(),status='complete' if good else 'discarded',
        objective=objective if objective is not None and math.isfinite(objective) else None,
        optimizer_evaluation_limits=len(re.findall(r'^result:\s*5\s*$',text,re.M)),
        seconds=time.monotonic()-started,folder=str(folder),tree=str(folder/'result.tre'))


def run_final(run, config, treepl, workers, on_start=lambda:None):
    def run_job(job):
        on_start()
        return final_fit(job)
    root=run.resolve();out=root/'final-checks';out.mkdir()
    settings=json.loads((root/'settings.json').read_text());points=list(csv.DictReader((root/'points.csv').open()))
    x=float(min(points,key=lambda z:float(z['median']))['x'])
    attempts=json.loads((root/'attempts.json').read_text())
    source_rows=[r for r in attempts if r['x']==x and r['status']=='complete' and Path(r['state']).exists()]
    donor=min(source_rows,key=lambda r:r['objective'])
    input_config=config.resolve();text=input_config.read_text();match=re.search(r'^\s*treefile\s*=\s*(\S+)',text,re.M)
    tree=str((input_config.parent/match.group(1)).resolve());binary=str(treepl.resolve())
    start=donor['state'];seed=settings['seed']+200000
    baseline=next(r for r in source_rows if r['replicate']==0)['profile']
    cv_method=baseline['optcvad']
    print(f'smoothing={10**x:g}; comparing six full-tree optimizers from the same saved state',flush=True)
    profiles=[dict(opt=i,optad=i,optcvad=cv_method,moredetail=0,moredetailad=0,moredetailcvad=0) for i in range(6)]
    jobs=[dict(x=x,profile=p,config=text,tree=tree,binary=binary,seed=seed,start=start,
               folder=str(out/f'optimizer-{p["opt"]}')) for p in profiles]
    screened=[]
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures=[pool.submit(run_job,job) for job in jobs]
        for future in as_completed(futures):
            row=future.result();screened.append(row);atomic_json(out/'optimizer-results.json',screened)
            print(f"final optimizer={row['profile']['opt']} {row['status']} objective={row['objective']} {row['seconds']:.1f}s",flush=True)
    valid_screen=[r for r in screened if r['status']=='complete']
    if not valid_screen: raise RuntimeError('All final optimizer fits failed')
    best=min(valid_screen,key=lambda r:(r['objective'],r['profile']['opt']!=baseline['opt'],r['profile']['opt'])); flag_rows=[]
    for method,flag in [('opt','moredetail'),('optad','moredetailad')]:
        if best['profile'][method]==0: continue
        profile={**best['profile'],flag:1-best['profile'][flag]}
        row=run_job(dict(x=x,profile=profile,config=text,tree=tree,binary=binary,seed=seed,start=start,folder=str(out/f'flag-{flag}')))
        flag_rows.append(row);atomic_json(out/'detail-results.json',flag_rows)
        if (row['status']=='complete' and
                (best['objective']-row['objective'])/max(1,abs(best['objective']))>1e-10): best=row
        print(f"{flag}: {row['status']}; {row['seconds']:.1f}s; selected={best['profile'][flag]}",flush=True)
    profile=best['profile'].copy();print('Final profile:',profile,flush=True)
    rows=[];pending=set(range(8));generation={r:0 for r in pending}
    while pending:
        jobs={r:dict(x=x,profile=profile,config=text,tree=tree,binary=binary,
                seed=settings['seed']+200000+r+1009*generation[r],
                folder=str(out/f'seed-{r+1}-attempt-{generation[r]+1}')) for r in pending}
        pool=ThreadPoolExecutor(max_workers=workers)
        try:
            futures={pool.submit(run_job,j):r for r,j in jobs.items()}
            for f in as_completed(futures):
                rep=futures[f];row=f.result();row.update(replicate=rep+1,attempt=generation[rep]+1);rows.append(row)
                if row['status']=='complete':pending.remove(rep)
                else:generation[rep]+=1
                atomic_json(out/'seed-results.json',rows)
                print(f"seed replicate {rep+1}: {row['status']} objective={row['objective']} {row['seconds']:.1f}s",flush=True)
        except BaseException:
            with LOCK:
                for proc in list(ACTIVE):proc.terminate()
            raise
        finally:pool.shutdown(wait=True,cancel_futures=True)
    valid=[r for r in rows if r['status']=='complete']
    winner=min(valid+[best],key=lambda r:r['objective'])
    check=subprocess.run([shutil.which('Rscript') or 'Rscript','-e',VALIDATE_R,
                          tree,winner['tree'],str(Path(winner['folder'])/'fit.config')],capture_output=True,text=True)
    if check.returncode:raise RuntimeError('Final tree validation failed: '+check.stderr)
    shutil.copyfile(tree,root/'input.tre');shutil.copyfile(winner['tree'],root/'dated.tre')
    clean='\n'.join(line for line in text.splitlines()
        if line.split('#',1)[0].partition('=')[0].strip() not in CONTROL)
    settings_out=dict(treefile='input.tre',outfile='fresh-fit.tre',seed=winner['seed'],nthreads=1,
                      smooth=f'{10**x:.17g}')
    settings_out.update({k:v for k,v in profile.items() if not k.startswith('moredetail')})
    config_lines=[clean]+[f'{k} = {v}' for k,v in settings_out.items()]
    config_lines += [k for k,v in profile.items() if k.startswith('moredetail') and v]
    (root/'recommended.config').write_text('\n'.join(config_lines)+'\n')
    atomic_json(out/'summary.json',dict(smoothing=10**x,log10_smoothing=x,profile=profile,
        minimum_median_cv=float(next(p['median'] for p in points if float(p['x'])==x)),best_fit=winner,
        objective_range=[min(r['objective'] for r in valid),max(r['objective'] for r in valid)],
        final_tree_check='passed with corrected treePL'))
    print('Finished:',json.dumps(winner),flush=True)


if __name__=='__main__':main()
