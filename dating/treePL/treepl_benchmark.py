#!/usr/bin/env python3
"""Select exploratory treePL settings in one fresh run, with a live summary figure.

Requires Python 3.9+, R/ape, patched treePL for optimization, and stock treePL for config checks.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED
import csv
import io
import math
import os
from pathlib import Path
import re
import queue
import shutil
import signal
import statistics
import subprocess
import sys
import tempfile
import threading
import time

OBJECTIVE_RTOL = 1e-10
OPT_KEYS = ('opt', 'optad', 'optcvad')
DETAIL_KEYS = ('moredetail', 'moredetailad', 'moredetailcvad')
CONTROL_KEYS = {'prime', 'cv', 'randomcv', 'cvstart', 'cvstop', 'cvmultstep',
                'cvoutfile', 'thorough', 'randomcviter', 'randomcvsamp', 'cvseed',
                'plsimaniter', 'cvsimaniter', 'calcgrad', 'siman', 'maxoptimiters',
                'paramverbose', 'mapspace', 'startstate', 'otherstate', 'stateout', 'cvlocal', 'polish'}
SCORE = re.compile(r'^chisq: \(([^)]+)\)\s*(\S+)', re.M)
OBJECTIVE = re.compile(r'^after opt calc:\s*(\S+)', re.M)


STAGES = [('01-algorithms','Algorithms'), ('02-effort','Search effort'),
          ('03-cv-algorithms','CV optimizer'), ('04-cv-effort','CV effort'),
          ('05-smoothing','Adaptive smoothing'), ('05b-cv-recheck','CV recheck'),
          ('06-final-fits','Final fits')]

FINAL_R = r"""
suppressPackageStartupMessages(library(ape))
a <- commandArgs(TRUE)
ref <- read.tree(a[1]); t <- read.tree(a[2]); out <- a[5]
if(!inherits(t,'phylo') || is.null(t$edge.length) || any(!is.finite(t$edge.length)) || any(t$edge.length<0))
  stop('Expected finite nonnegative branch lengths.')
if(!isTRUE(all.equal.phylo(ref,t,use.edge.length=FALSE,use.tip.label=TRUE))) stop('Topology or taxa changed.')
ages <- function(t) {
  d <- node.depth.edgelength(t); max(d[seq_len(Ntip(t))])-d
}
d <- node.depth.edgelength(t)
if(diff(range(d[seq_len(Ntip(t))]))>.001) stop('Dated tree is not ultrametric.')
entries <- lapply(trimws(sub('#.*$','',readLines(a[3]))),function(x)
  strsplit(trimws(gsub('=',' ',x,fixed=TRUE)),'[[:space:]]+')[[1]])
pairs <- Filter(function(x)length(x)>0 && x[1]=='mrca',entries)
if(!length(pairs)) stop('No calibrations in config.')
node_ages <- ages(t)
for(p in pairs) {
  node <- getMRCA(t,p[-(1:2)]); age <- node_ages[node]
  for(k in c('min','max')) {
    v <- Filter(function(x)length(x)>1 && x[1]==k && x[2]==p[2],entries)
    if(!length(v)) next
    b <- as.numeric(v[[1]][3])
    if((k=='min' && age<b-.001) || (k=='max' && age>b+.001)) stop('Calibration violation: ',p[2])
  }
}
keys <- function(t) {
  ch <- split(t$edge[,2],t$edge[,1]); memo <- vector('list',Ntip(t)+t$Nnode)
  descend <- function(n) {
    if(length(memo[[n]])) return(memo[[n]])
    memo[[n]] <<- if(n<=Ntip(t))t$tip.label[n] else sort(unlist(lapply(ch[[as.character(n)]],descend)))
    memo[[n]]
  }
  vapply(seq.int(Ntip(t)+1,Ntip(t)+t$Nnode),function(n)paste(descend(n),collapse='|'),character(1))
}
reference_keys <- keys(ref)
aligned <- function(t) ages(t)[Ntip(t)+match(reference_keys,keys(t))]
fits <- read.delim(a[4],stringsAsFactors=FALSE)
reference <- which.min(fits$objective)
values <- lapply(fits$path,function(p)aligned(read.tree(p)))
r <- values[[reference]]
rows <- lapply(setdiff(seq_along(values),reference),function(i)
  data.frame(id=fits$id[i],node=seq_along(r)+Ntip(ref),reference_age_ma=r,difference_ma=values[[i]]-r))
if(length(rows)) write.table(do.call(rbind,rows),file.path(out,'age_deviations.tsv'),sep='\t',quote=FALSE,row.names=FALSE)
cat('Final tree satisfies constraints.')
if(length(values)>1) cat(' Maximum independent age difference:',max(abs(unlist(values)-rep(r,length(values)))),'Ma')
cat('\n')
"""


PLOT_R = r'''
a <- commandArgs(TRUE); root <- a[1]; label <- a[2]; output <- a[3]
read <- function(name) {
  p <- file.path(root,name)
  if(file.exists(p)) read.delim(p,stringsAsFactors=FALSE) else data.frame()
}
progress <- read('plot-progress.tsv'); fits <- read('plot-fits.tsv')
cv <- read('plot-cv.tsv'); state <- read('plot-state.tsv')
deviations <- read('age_deviations.tsv')
blue <- '#166b83'; orange <- '#bd6836'; grey <- '#84909a'; ink <- '#142b36'
empty <- function(heading, message, note) {
  plot.new(); title(heading,adj=0,font.main=2,col.main=ink)
  text(.5,.56,message,cex=1.05,col='#667781')
  text(.5,.42,note,cex=.8,col=grey)
}
draw <- function() {
  par(mfrow=c(2,2),mar=c(4.8,5.2,5.4,1.6),oma=c(2,0,3,0),family='sans',
      col.axis='#374151',col.lab='#374151',fg='#374151')
  plot.new(); title('Progress',adj=0,font.main=2,col.main=ink)
  y <- seq(.87,.1,length.out=nrow(progress))
  for(i in seq_len(nrow(progress))) {
    text(0,y[i],progress$label[i],adj=0,cex=.9)
    rect(.48,y[i]-.014,.8,y[i]+.014,col='#e7edef',border=NA)
    n <- progress$planned[i]; good <- progress$complete[i]; bad <- progress$failed[i]
    if(n>0) {
      rect(.48,y[i]-.014,.48+.32*good/n,y[i]+.014,col=blue,border=NA)
      if(bad>0) rect(.48+.32*good/n,y[i]-.014,.48+.32*(good+bad)/n,y[i]+.014,col=orange,border=NA)
      text(.86,y[i],paste0(good,'/',n),adj=0,cex=.85)
    } else text(.86,y[i],'Waiting',adj=0,cex=.8,col=grey)
  }
  if(any(progress$failed>0)) text(0,-.02,'Orange: discarded attempts',adj=0,cex=.75,col=orange)
  if(nrow(fits)) {
    par(mar=c(4.8,12,5.4,1.6))
    profiles <- unique(fits$profile)
    names <- vapply(profiles,function(p)fits$label[match(p,fits$profile)],character(1))
    z <- match(fits$profile,profiles); sm <- sort(unique(fits$smoothing))
    colours <- c(blue,orange,'#709e80')
    limits <- c(-12,max(-9,log10(max(fits$gap,1e-12))))
    plot(log10(pmax(fits$gap,1e-12)),z,xlim=limits,ylim=c(.5,length(profiles)+.5),
      yaxt='n',ylab='',xlab='Relative objective gap (log10; lower is better)',pch=16,
      col=adjustcolor(colours[match(fits$smoothing,sm)],.7),cex=.8)
    axis(2,at=seq_along(profiles),labels=names,las=1,cex.axis=.65)
    abline(v=-10,lty=2,col=orange)
    title(if(state$fit_phase[1]=='06-final-fits') 'Stock treePL fits' else paste('Optimizer comparison:',state$fit_phase[1]),adj=0,font.main=2,col.main=ink,cex.main=.95,line=3.6)
    mtext('Labels: opt/optad | PL iter | anneal | ftol | detail flags',side=3,line=2.2,cex=.57,adj=0)
    mtext('Reference minimum is specific to smoothing; gaps below 1e-12 shown at left.',side=3,line=1.2,cex=.52,adj=0)
    if(length(sm)>1) legend('bottomright',legend=paste('Smoothing',format(sm)),col=colours[seq_along(sm)],pch=16,bty='n',cex=.65)
    par(mar=c(4.8,5.2,5.4,1.6))
  } else empty('Optimizer comparison','Awaiting completed fits','Settings and objective differences will appear here.')
  saved <- file.path(output,'results.tsv')
  saved <- if(file.exists(saved)) read.delim(saved,stringsAsFactors=FALSE) else data.frame()
  if(nrow(cv)) {
    plot(cv$smoothing,pmax(cv$score,1e-300),log='xy',type='n',xlab='Smoothing',ylab='CV score (log scale)')
    for(rep in unique(cv$replicate)) {
      g <- cv[cv$replicate==rep,]; g <- g[order(g$smoothing),]
      lines(g$smoothing,pmax(g$score,1e-300),type='b',pch=16,cex=.35,col=adjustcolor(grey,.3))
    }
    if(nrow(saved)) {
      g <- saved[order(saved$smoothing),]
      lines(g$smoothing,pmax(g$median_cv,1e-300),lwd=2,col=blue)
      points(g$smoothing,pmax(g$median_cv,1e-300),pch=ifelse(g$origin=='coarse',1,16),col=blue)
      chosen <- g[tolower(as.character(g$selected))=='true',]
      points(chosen$smoothing,chosen$median_cv,pch=18,col=orange,cex=1.2)
    }
    legend('topleft',legend=c('Coarse grid','Added values','Selected'),
           col=c(blue,blue,orange),pch=c(1,16,18),bty='n',cex=.7)
    title('Adaptive smoothing',adj=0,font.main=2,col.main=ink,line=3.6)
    mtext(paste0('Blue: median; grey: ',state$replicates[1],' paired replicates. Prefer larger smoothing within ',
                 100*state$tolerance[1],'%.'),side=3,line=2.2,cex=.6,adj=0)
    cvregion <- par('fig'); cvarea <- par('plt')
  } else empty('Adaptive smoothing','Awaiting CV scores','')
  if(nrow(deviations)) {
    delta <- deviations$difference_ma; span <- max(abs(delta),1e-6)*1.1
    plot(deviations$reference_age_ma,delta,pch=16,col=adjustcolor(blue,.3),cex=.5,
         xlab='Node age in best observed fit (Ma)',ylab='Difference from best fit (Ma)',ylim=c(-span,span))
    abline(h=0,col=orange,lty=2)
    title('Independent corrected fits',adj=0,font.main=2,col.main=ink,line=3.6)
    mtext('Zero is ideal. Positive: older; negative: younger. Reference fit excluded; descriptive comparison.',side=3,line=2.2,cex=.59,adj=0)
    mtext(paste0(length(unique(deviations$id)),' comparison fits; maximum absolute difference ',
                 format(max(abs(delta)),digits=3),' Ma. Axis follows observed variation.'),side=3,line=1.2,cex=.55,adj=0)
    old <- par(no.readonly=TRUE); region <- par('fig'); area <- par('plt')
    inset <- c(area[1]+.58*diff(area[1:2]),area[2]-.02*diff(area[1:2]),
               area[3]+.55*diff(area[3:4]),area[4]-.02*diff(area[3:4]))
    par(fig=c(region[1]+inset[1:2]*diff(region[1:2]),region[3]+inset[3:4]*diff(region[3:4])),
        mar=c(1.8,1.8,.8,.4),new=TRUE,cex.axis=.55,cex.lab=.55)
    plot(ecdf(abs(delta)),xlim=c(0,max(abs(delta),1e-6)),ylim=c(0,1),verticals=TRUE,
         do.points=FALSE,col=blue,lwd=1.5,main='',axes=FALSE,ann=FALSE)
    axis(1,at=pretty(c(0,max(abs(delta),1e-6)),n=3),cex.axis=.5)
    axis(2,at=c(0,1),labels=c('0%','100%'),las=1,cex.axis=.5);box()
    title('Cumulative |age difference| (Ma)',cex.main=.55,line=.2)
    par(old)
  } else if(state$status[1]=='Complete') {
    empty('Node-age differences','One near-best fit','No between-fit comparison.')
  } else empty('Node-age differences','Awaiting final fits','Signed differences and their distribution will appear here.')
    if(nrow(cv) && nrow(saved)>1) {
      old <- par(no.readonly=TRUE); region <- cvregion; area <- cvarea
      inset <- c(area[1]+.55*diff(area[1:2]),area[2]-.02*diff(area[1:2]),
                 area[3]+.59*diff(area[3:4]),area[4]-.02*diff(area[3:4]))
      par(fig=c(region[1]+inset[1:2]*diff(region[1:2]),region[3]+inset[3:4]*diff(region[3:4])),
          mar=c(1.8,1.8,.8,.4),new=TRUE,cex.axis=.5)
      gap <- 100*(g$median_cv/min(g$median_cv)-1)
      plot(g$smoothing,gap,log='x',type='n',ylim=c(0,max(5,200*state$tolerance[1])),
           main='',xlab='',ylab='')
      u <- par('usr'); rect(10^u[1],u[3],10^u[2],u[4],col='white',border=NA)
      abline(h=100*state$tolerance[1],col=orange,lty=2)
      lines(g$smoothing,gap,type='b',pch=16,cex=.3,col=blue); box()
      title('Above best median (%)',cex.main=.55,line=.2)
      par(old)
    }
  mtext(paste0(label,' | treePL optimization'),outer=TRUE,side=3,line=1,adj=.02,cex=1.4,font=2,col=ink)
  mtext(paste0(state$status[1],' | ',format(Sys.time(),'%Y-%m-%d %H:%M %Z'),
               ' | ',state$complete[1],' attempts complete'),outer=TRUE,side=1,line=.2,adj=.02,cex=.75,col='#667781')
}
png(file.path(output,'summary.tmp.png'),width=1800,height=1300,res=160);draw();dev.off()
if(!file.rename(file.path(output,'summary.tmp.png'),file.path(output,'summary.png'))) stop('Cannot replace summary.png')
'''


def atomic(path, text):
    temporary = path.with_name(path.name + '.tmp')
    temporary.write_text(text)
    temporary.replace(path)


def table(path, rows):
    if not rows:
        path.unlink(missing_ok=True)
        return
    out = io.StringIO()
    writer = csv.DictWriter(out, fieldnames=list(rows[0]), delimiter='\t', lineterminator='\n')
    writer.writeheader()
    writer.writerows(rows)
    atomic(path, out.getvalue())


def entries(text):
    for raw in text.splitlines():
        line = raw.split('#', 1)[0].strip()
        if not line or not line[0].isalpha():
            continue
        key, sep, value = line.partition('=')
        yield key.strip(), value.strip() if sep else True


def settings(text):
    result = {}
    for key, value in entries(text):
        if key in ('mrca', 'min', 'max'):
            continue
        if key in result:
            raise ValueError(f'Duplicate setting: {key}')
        result[key] = value
    return result


def render_config(original, updates, flags):
    replaced = CONTROL_KEYS | set(updates) | set(flags)
    lines = []
    for raw in original.splitlines():
        key = raw.lstrip().lstrip('#').split('#', 1)[0].partition('=')[0].strip()
        if key not in replaced:
            lines.append(raw)
    controls = [f'{k} = {v}' for k, v in updates.items()]
    controls += [k for k, enabled in flags.items() if enabled]
    return '\n'.join(controls + [''] + lines) + '\n'


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


def profile(opt=0, optad=0, optcvad=3, moredetail=0, moredetailad=0,
            moredetailcvad=0, pliter=50, cviter=3, lfsimaniter=1500, ftol=1e-8):
    p = dict(opt=opt, optad=optad, optcvad=optcvad, moredetail=moredetail,
             moredetailad=moredetailad, moredetailcvad=moredetailcvad,
             pliter=pliter, cviter=cviter, lfsimaniter=lfsimaniter, ftol=ftol)
    for k, d in zip(OPT_KEYS, DETAIL_KEYS):
        if p[k] == 0:  # TNC does not use the NLopt detail flag.
            p[d] = 0
    return p


def changed(p, **kwargs):
    return profile(**{**p, **kwargs})


def parse_args(argv=None):
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('config', type=Path)
    p.add_argument('--output', type=Path, required=True, help='new output directory')
    p.add_argument('--treepl', default='treePL', help='executable built with treepl-fixes.patch')
    p.add_argument('--stock-treepl', default='treePL', help='unmodified executable for config checks (default: treePL)')
    p.add_argument('--rscript', default='Rscript')
    p.add_argument('--jobs', type=int, default=4, help='concurrent single-threaded processes (default: 4)')
    p.add_argument('--seed', type=int, default=20261031, help='base seed (default: 20261031)')
    p.add_argument('--cv-replicates', type=int, default=8, help='paired CV replicates throughout the search (default: 8)')
    p.add_argument('--cv-tolerance', type=float, default=.01, help='relative CV tolerance; prefer larger smoothing within it (default: .01)')
    p.add_argument('--log-step', type=float, default=.25, help='final log10 smoothing step (default: .25)')
    p.add_argument('--cv-score-ceiling', type=float, default=1e12, help='discard pathological CV scores above this value (default: 1e12)')
    p.add_argument('--smoothing-values', default='1e4,1e2,1,1e-2,1e-4,1e-6,1e-8,1e-10',
                   help='positive coarse grid; refined around competitive minima')
    a = p.parse_args(argv)
    if a.jobs < 1 or not 1 <= a.seed <= 2147000000:
        p.error('jobs must be positive; seed must be between 1 and 2147000000')
    if a.cv_replicates < 3:
        p.error('use at least three paired CV replicates')
    if not math.isfinite(a.cv_tolerance) or not 0 <= a.cv_tolerance < 1:
        p.error('cv-tolerance must be between zero and one')
    if not math.isfinite(a.log_step) or a.log_step <= 0:
        p.error('log-step must be finite and positive')
    if not math.isfinite(a.cv_score_ceiling) or a.cv_score_ceiling <= 0:
        p.error('CV score ceiling must be finite and positive')
    try:
        a.grid = sorted({float(s) for s in a.smoothing_values.split(',')}, reverse=True)
        if len(a.grid) < 3 or any(not math.isfinite(s) or s <= 0 for s in a.grid):
            raise ValueError()
    except ValueError:
        p.error('provide at least three distinct, finite, positive smoothing values')
    return a




def parse_cv(log, saved, smoothing):
    printed = list(SCORE.finditer(log))
    matches = [(i,m) for i,m in enumerate(printed) if math.isclose(float(m[1]),smoothing,rel_tol=1e-5)]
    written = [(float(sm),float(score)) for sm,score in SCORE.findall(saved)
               if math.isclose(float(sm),smoothing,rel_tol=1e-5)]
    if len(matches)!=1 or len(written)!=1 or 'conducting RANDOM SUBSAMPLE' not in log:
        raise ValueError('Missing or unexpected randomCV output')
    i,m = matches[0]
    score,wscore = float(m[2]),written[0][1]
    if not all(math.isfinite(v) and v >= 0 for v in (score,wscore)) or not math.isclose(score,wscore,rel_tol=5e-6):
        raise ValueError('Nonfinite, negative, or inconsistent CV score')
    start = printed[i-1].end() if i else 0
    folds = [float(x) for x in re.findall(r'^post opt cv check:\s*(\S+)',log[start:m.start()],re.M)]
    samples = re.findall(r'^cv sample (\d+):([^\n]*)', log, re.M)
    if len(folds) != 10 or not all(math.isfinite(x) for x in folds):
        raise ValueError('Expected ten finite CV training objectives')
    if [int(i) for i, _ in samples] != list(range(10)):
        raise ValueError('Missing or unordered CV sample records')
    masks = [sorted(taxa.split()) for _, taxa in samples]
    if any(not m or len(set(m)) != len(m) for m in masks):
        raise ValueError('Empty or duplicate CV sample')
    return score, folds, masks


def profile_key(p):
    return tuple(sorted(p.items()))


def unique(profiles):
    return list({profile_key(p): p for p in profiles}.values())


def accepted(score, ceiling):
    return score is not None and math.isfinite(score) and 0 <= score <= ceiling


def rank_profiles(results, cv=False):
    """Compare training objectives at matched smoothing values and CV folds."""
    groups, best = {}, {}
    for r in results:
        if r['status'] != 'complete':
            continue
        j = r['job']
        groups.setdefault(profile_key(j['profile']), []).append(r)
        for i, value in enumerate(r['folds'] if cv else [r['objective']]):
            key = (j['smoothing'], j['seed'], i) if cv else (j['smoothing'],)
            best[key] = min(value, best.get(key, math.inf))
    ranked = []
    for group in groups.values():
        gaps = []
        for r in group:
            j = r['job']
            for i, value in enumerate(r['folds'] if cv else [r['objective']]):
                key = (j['smoothing'], j['seed'], i) if cv else (j['smoothing'],)
                gaps.append((value-best[key])/max(abs(best[key]), 1))
        gap = statistics.median(gaps)
        seconds = statistics.median(r['seconds'] for r in group)
        ranked.append((gap, seconds, group[0]['job']['profile']))
    if not ranked:
        raise ValueError('No successful fits in optimizer comparison')
    def order(row):
        gap, seconds, p = row
        if gap > OBJECTIVE_RTOL:
            return (1, gap, profile_key(p))
        effort = (p['moredetailcvad'], p['cviter']) if cv else ()
        return (0, *effort, seconds, profile_key(p))
    return [p for gap, seconds, p in sorted(ranked, key=order)]


def descending_groups(values):
    """Partition log-smoothing values into native geometric sweeps."""
    values = sorted(set(values), reverse=True)
    while values:
        group = values[:2]
        values = values[len(group):]
        if len(group) == 2:
            step = group[0]-group[1]
            while values and math.isclose(group[-1]-values[0], step, abs_tol=1e-9):
                group.append(values.pop(0))
        yield group


def polish_methods(profiles, cvopt):
    """Carry distinct screened methods into full and CV fitting."""
    methods = []
    for p in profiles:
        if (p['opt'],p['optad']) not in [m[:2] for m in methods]:
            methods.append((p['opt'],p['optad'],cvopt))
        if len(methods)==3:
            break
    return tuple(methods)


def refinement_points(scores, resolution=.25, tolerance=.01):
    """Bisect around competitive minima; extend improving domain edges."""
    xs = sorted(scores)
    best = min(scores.values())
    proposed = set()
    for i,x in enumerate(xs):
        neighbors = xs[max(0,i-1):i] + xs[i+1:i+2]
        if scores[x] > best*1.2 or any(scores[y] < scores[x] for y in neighbors):
            continue
        if (i == 0 or i == len(xs)-1) and not math.isclose(
                scores[x],scores[neighbors[0]],rel_tol=1e-10,abs_tol=1e-8):
            direction = -1 if i == 0 else 1
            proposed.add(round(x+direction*min(abs(neighbors[0]-x),1),10))
        # A flat region already has a representative; finer spacing adds little.
        if all(scores[y]-scores[x] <= tolerance*max(abs(scores[x]),1) for y in neighbors):
            continue
        for y in neighbors:
            if abs(y-x) > resolution+1e-9:
                proposed.add(round((x+y)/2,10))
    return sorted(proposed-set(xs))


def better_training(new, old):
    """Accept improved training fits even when their prediction score increases."""
    a = [new['objective']] + new['folds']
    b = [old['objective']] + old['folds']
    return (all(x <= y+max(1e-8,abs(y)*OBJECTIVE_RTOL) for x,y in zip(a,b))
            and any(x < y for x,y in zip(a,b)))


def select_smoothing(scores, tolerance):
    limit = min(scores.values()) * (1+tolerance)
    return max(x for x,score in scores.items() if score <= limit)


def smoothing_candidates(scores, coarse, tolerance):
    """Revisit the coarse grid and every local minimum, including distant alternatives."""
    xs = sorted(scores)
    minima = [x for i,x in enumerate(xs)
              if scores[x] <= (scores[xs[i-1]] if i else math.inf)
              and scores[x] < (scores[xs[i+1]] if i+1 < len(xs) else math.inf)]
    return sorted(set(coarse).intersection(scores) | set(minima)
                  | {select_smoothing(scores,tolerance)})


class SmoothingSearch:
    """One adaptive grid, with fixed paired replicates and replaceable fitted states."""
    def __init__(self, evaluate, grid, seed, replicates=8, resolution=.25,
                 tolerance=.01, report=None, recheck=None):
        self.evaluate, self.report = evaluate, report or (lambda search: None)
        self.recheck = recheck or (lambda search: None)
        self.coarse = sorted(round(math.log10(x),10) for x in grid)
        self.seed, self.n, self.resolution, self.tolerance = seed,replicates,resolution,tolerance
        self.samples, self.attempts, self.discards = {}, {}, {}
        self.round = 0

    def medians(self):
        xs = sorted({x for x,rep in self.samples})
        return {x:statistics.median(self.samples[x,r]['score'] for r in range(self.n))
                for x in xs if all((x,r) in self.samples for r in range(self.n))}

    def ensure(self, xs, refresh=False, coarse=False, explore=False, donor=None):
        xs = sorted({round(x,10) for x in xs})
        if any(not -300 < x < 300 for x in xs):
            raise ValueError('Smoothing search exceeded floating-point range')
        pending = {(x,r) for x in xs for r in range(self.n)
                   if refresh or (x,r) not in self.samples}
        first = True
        while pending:
            requests = []
            for rep in range(self.n):
                values = [x for x,r in pending if r==rep]
                groups = descending_groups(values) if first and coarse else ([x] for x in sorted(values,reverse=True))
                for group in groups:
                    attempt = max(self.attempts.get((x,rep),0) for x in group)
                    for x in group:
                        self.attempts[x,rep] = attempt+1
                    requests.append(dict(xs=group,rep=rep,donor=donor,
                        cvseed=(self.seed+100000+rep)%2147483000+1,
                        seed=(self.seed+100030+rep+1009*attempt)%2147483000+1,
                        coarse=first and coarse,
                        explore=(first and coarse) or (explore and rep==self.round%self.n) or not first))
            for row in self.evaluate(requests):
                key = (round(math.log10(row['job']['smoothing']),10),row['job']['rep'])
                if key not in pending:
                    continue
                old = self.samples.get(key)
                if row['status']=='complete':
                    if old is None or better_training(row,old):
                        self.samples[key] = row
                    pending.remove(key)
                else:
                    self.discards[key[0]] = self.discards.get(key[0],0)+1
                    if old is not None:
                        pending.remove(key)  # Keep the earlier valid fit during an unsuccessful polish.
            first = False
        self.report(self)
        return self.medians()

    def run(self):
        for group in descending_groups(self.coarse):
            self.ensure(group,coarse=True)
        # Reverse the initial continuation once to spread improved fits back up the grid.
        for x in self.coarse:
            self.ensure([x],refresh=True)
        self.refine()
        while True:
            before = self.medians()
            self.recheck(self)
            candidates = smoothing_candidates(self.medians(),self.coarse,self.tolerance)
            donor = candidates[0]
            for sweep in (list(reversed(candidates)),candidates):
                for x in sweep:
                    self.ensure([x],refresh=True,donor=donor)
                    donor = x
            self.refine()
            after = self.medians()
            shift = max(abs(after[x]-before[x])/max(abs(before[x]),1) for x in before)
            print(f'Final smoothing comparison: maximum median change {100*shift:.3g}%',flush=True)
            if (before.keys()==after.keys() and shift <= max(self.tolerance,1e-10)
                    and select_smoothing(before,self.tolerance)==select_smoothing(after,self.tolerance)):
                return 10**select_smoothing(after,self.tolerance)

    def refine(self):
        while True:
            scores = self.medians()
            new = refinement_points(scores,self.resolution,self.tolerance)
            if not new:
                return
            old = sorted(scores)
            self.round += 1
            self.ensure(new,explore=True)
            adjacent = set()
            for x in new:
                left,right = [y for y in old if y<x],[y for y in old if y>x]
                adjacent.update(left[-1:]+right[:1])
            for x in sorted(adjacent):
                self.ensure([x],refresh=True)


class Optimizer:
    def __init__(self, args):
        self.a = args
        self.config = args.config.resolve()
        self.original = self.config.read_text()
        options = settings(self.original)
        self.tree = (self.config.parent / str(options['treefile'])).resolve()
        self.root = args.output.resolve()
        self.binary, self.stock_binary = shutil.which(args.treepl), shutil.which(args.stock_treepl)
        self.rscript = shutil.which(args.rscript)
        if not self.binary or not self.stock_binary or not self.rscript or not self.tree.is_file():
            raise ValueError('Supply an input tree, patched and stock treePL executables, and Rscript')
        if os.path.samefile(self.binary,self.stock_binary):
            raise ValueError('--treepl and --stock-treepl must use separate patched and stock executables')
        if not math.isfinite(float(options.get('numsites', 0))) or float(options.get('numsites', 0)) <= 0:
            raise ValueError('numsites must be positive')
        if any(k in options for k in ('collapse', 'set1', 'ind8s', 'inr8s', 'sample', 'log_pen')):
            raise ValueError('Unsupported tree-transforming or alternative objective option in config')
        version = subprocess.run([self.binary, '--version'], capture_output=True, text=True)
        if version.returncode or 'vgp-optimizer-fixes-8' not in version.stdout:
            raise ValueError('Use treePL built with the documented treepl-fixes.patch')
        check = subprocess.run([self.rscript, '-e', 'library(ape)'], capture_output=True, text=True)
        if check.returncode:
            raise ValueError('R package ape is required')
        self.stop = threading.Event()
        self.jobs, self.results, self.plans, self.curves = {}, {}, {}, {}
        self.last_plot, self.finished = 0, False
        self.events, self.done = queue.Queue(), set()
        self.plot_dirty, self.plot_enabled = True, True
        self.polish = ()

    def job(self, p, sm, seed, kind='fit', grid=None, cvseed=None, rep=0, starts=(None,None), continuation=False, polish=()):
        grid = tuple(grid or [sm])
        cvseed = cvseed if cvseed is not None else seed+100000
        key = (kind,profile_key(p),grid,seed,cvseed,starts,continuation,polish)
        if key not in self.jobs:
            self.jobs[key] = dict(id=f'{kind}-{len(self.jobs)+1:04d}',profile=p,smoothing=sm,
                                 grid=grid,seed=seed,cvseed=cvseed,rep=rep,kind=kind,starts=starts,continuation=continuation,polish=polish)
        return self.jobs[key]

    def fit(self, j):
        directory = self.work/j['id']
        directory.mkdir()
        p,grid = j['profile'],j['grid']
        updates = dict(treefile=str(self.tree),outfile='result.tre',seed=j['seed'],nthreads=1,
            smooth=str(grid[0]),lfiter=3,xtol=-1,
            **{k:v for k,v in p.items() if k not in DETAIL_KEYS})
        if j['kind'] != 'stock':
            updates['stateout'] = 'state'
        flags = {k:bool(p[k]) for k in DETAIL_KEYS}
        updates.update({k:v for k,v in zip(('startstate','otherstate'),j['starts']) if v})
        if j['polish']:
            updates['polish'] = ','.join('/'.join(map(str,m)) for m in j['polish'])
        if j['kind'] == 'cv':
            flags.update(cv=True,randomcv=True,cvlocal=j["continuation"])
            updates.update(cvseed=j['cvseed'],cvstart=format(grid[0],'.17g'),
                cvstop=format(grid[-1]*(1-1e-9),'.17g'),
                cvmultstep=format(grid[1]/grid[0] if len(grid)>1 else .1,'.17g'),cvoutfile='cv.out')
        (directory/'fit.config').write_text(render_config(self.original,updates,flags))
        began,seen = time.monotonic(),set()
        def emit(index,score=None,folds=None,masks=None,objective=None):
            seen.add(index)
            good = accepted(score,self.a.cv_score_ceiling) if j['kind']=='cv' else objective is not None
            item = dict(j,id=f'{j["id"]}:{index}' if j['kind']=='cv' else j['id'],smoothing=grid[index])
            state = directory/(f'state.{index}' if j['kind']=='cv' else 'state')
            self.events.put(dict(job=item,parent=j['id'],status='complete' if good else 'discarded',
                objective=objective,score=score,folds=folds or [],masks=masks or [],
                state=str(state) if state.exists() else None,
                seconds=(time.monotonic()-began)/len(seen)))
        with (directory/'run.log').open('w') as log:
            binary = self.stock_binary if j['kind']=='stock' else self.binary
            proc = subprocess.Popen([binary,'fit.config'],cwd=directory,stdout=log,stderr=subprocess.STDOUT,
                start_new_session=True,env={**os.environ,'OMP_NUM_THREADS':'1'})
            try:
                while True:
                    if self.stop.wait(.1):
                        raise InterruptedError('Interrupted')
                    ended = proc.poll() is not None
                    if ended and proc.returncode:
                        text = (directory/'run.log').read_text(errors='replace')
                        raise RuntimeError(f'treePL exited {proc.returncode}:\n'+text[-2000:])
                    if j['kind']=='cv':
                        cvfile = directory/'cv.out'
                        saved = cvfile.read_text() if cvfile.exists() else ''
                        available = [float(sm) for sm,_ in SCORE.findall(saved)]
                        ready = [i for i,sm in enumerate(grid) if i not in seen
                                 and any(math.isclose(sm,v,rel_tol=1e-5) for v in available)]
                        if ready or ended:
                            # Scores are flushed after the log; read it only for new scores or exit.
                            text = (directory/'run.log').read_text(errors='replace')
                            printed = list(SCORE.finditer(text))
                        for i in ready:
                            sm = grid[i]
                            try:
                                score,folds,masks = parse_cv(text,saved,sm)
                                at = next(k for k,m in enumerate(printed) if math.isclose(float(m[1]),sm,rel_tol=1e-5))
                                full = OBJECTIVE.findall(text[printed[at-1].end() if at else 0:printed[at].start()])
                                emit(i,score,folds,masks,objective=float(full[-1]) if full else None)
                            except ValueError:
                                emit(i)
                        if len(seen)==len(grid):
                            break  # Omit treePL's redundant post-CV full-tree fit.
                        if ended:
                            if not seen:
                                raise RuntimeError('treePL exited without a CV score:\n'+text[-2000:])
                            for i in set(range(len(grid)))-seen:
                                emit(i)  # A failed sweep is retried with a new optimization seed.
                            break
                    elif ended:
                        text = (directory/'run.log').read_text(errors='replace')
                        values = OBJECTIVE.findall(text)
                        value = float(values[-1]) if values else math.nan
                        valid = math.isfinite(value) and value < 1e15 and (directory/'result.tre').exists()
                        emit(0,objective=value if valid else None)
                        break
            finally:
                terminate(proc)

    def batch(self, name, jobs):
        new_stage = name not in self.plans
        plan = self.plans.setdefault(name,{})
        plan.update({j['id']:j for j in jobs})
        pending = [j for j in jobs if j['id'] not in self.done]
        self.plot_dirty |= new_stage or bool(pending)
        self.plot(force=new_stage)
        with ThreadPoolExecutor(max_workers=self.a.jobs) as pool:
            futures = {pool.submit(self.fit,j):j for j in pending}
            try:
                while futures:
                    done,_ = wait(futures,timeout=2,return_when=FIRST_COMPLETED)
                    for future in done:
                        future.result()
                        self.done.add(futures.pop(future)['id'])
                    while not self.events.empty():
                        r = self.events.get_nowait()
                        self.results[r['job']['id']] = r
                        self.plot_dirty = True
                    self.plot()
            except BaseException:
                self.stop.set()
                raise
        self.plot()
        ids = {j['id'] for j in jobs}
        done = [r for r in self.results.values() if r['parent'] in plan]
        print(f'{name}: {sum(r["status"]=="complete" for r in done)} accepted, '
              f'{sum(r["status"]!="complete" for r in done)} discarded',flush=True)
        return [r for r in self.results.values() if r['parent'] in ids]

    def compare(self, name, profiles, grid, seeds, kind='fit'):
        return self.batch(name,[self.job(p,sm,s,kind)
            for p in unique(profiles) for sm in grid for s in seeds])

    def curve_starts(self, sm, rep, donor=None):
        """Continue each replicate's own full and CV fits."""
        x = math.log10(sm)
        sources = sorted({v for v,r in self.curves if r==rep},key=lambda v:(abs(v-x),-v))
        if donor is not None:
            sources = list(dict.fromkeys([round(x,10),donor]+sources))
        starts = []
        for v in sources:
            own = self.curves.get((v,rep))
            if own is None:
                continue
            starts.append(own['state'])
        return tuple((starts+[None,None])[:2])

    def smoothing(self, p):
        rechecked = set()
        def evaluate(requests):
            jobs = []
            for req in requests:
                grid = [10**x for x in req['xs']]
                starts = (None,None) if not self.curves else self.curve_starts(grid[0],req['rep'],req['donor'])
                local = p if req['explore'] else changed(p,lfsimaniter=0)
                jobs.append(self.job(local,grid[0],req['seed'],'cv',grid,req['cvseed'],req['rep'],
                                     starts,continuation=req['coarse'],polish=self.polish))
            return self.batch('05-smoothing',jobs)
        def recheck(search):
            nonlocal p
            scores = search.medians()
            chosen = select_smoothing(scores,search.tolerance)
            anchors = {chosen,min(search.coarse,key=lambda x:scores[x])}
            alternatives = [x for x in smoothing_candidates(scores,search.coarse,search.tolerance)
                            if all(abs(x-a)>=2 for a in anchors)]
            if alternatives:
                anchors.add(min(alternatives,key=lambda x:scores[x]))
            new = anchors-rechecked
            if not new:
                return
            jobs = [self.job(changed(p,optcvad=i,lfsimaniter=0),10**x,search.seed+500+rep,'cv',
                        cvseed=(search.seed+100000+rep)%2147483000+1,rep=rep,
                        starts=self.curve_starts(10**x,rep),
                        polish=tuple((a,b,i) for a,b,_ in self.polish))
                    for x in sorted(new) for i in range(6) for rep in range(2)]
            rows = self.batch('05b-cv-recheck',jobs)
            winner = rank_profiles(rows,cv=True)[0]['optcvad']
            p = changed(p,optcvad=winner)
            self.polish = tuple((a,b,winner) for a,b,_ in self.polish)
            for row in rows:
                key = (round(math.log10(row['job']['smoothing']),10),row['job']['rep'])
                if row['status']=='complete' and better_training(row,search.samples[key]):
                    search.samples[key] = row
            rechecked.update(new)
            print(f'CV recheck: optimizer {winner}; smoothing '+', '.join(f'{10**x:g}' for x in sorted(new)),flush=True)
            report(search)
        def report(search):
            scores = search.medians()
            if not scores:
                return
            best = min(scores,key=lambda x:(scores[x],-x))
            selected = select_smoothing(scores,search.tolerance)
            table(self.root/'results.tsv',[dict(smoothing=10**x,origin='coarse' if x in search.coarse else 'refined',
                accepted=search.n,discarded=search.discards.get(x,0),median_cv=score,selected=x==selected,
                **{f'cv_{rep+1}':search.samples[x,rep]['score'] for rep in range(search.n)})
                for x,score in sorted(scores.items(),reverse=True)])
            self.plot_dirty = True
            self.plot()
            print(f'Smoothing: {len(scores)} values; lowest median {scores[best]:g}; '
                  f'selected {10**selected:g} (median {scores[selected]:g})',flush=True)
        search = SmoothingSearch(evaluate,self.a.grid,self.a.seed,self.a.cv_replicates,
                                 self.a.log_step,self.a.cv_tolerance,report,recheck)
        self.curves = search.samples
        return search.run(),p

    def plot(self, force=False):
        if not self.plot_enabled or (not force and (not self.plot_dirty or time.monotonic()-self.last_plot < 5)):
            return
        self.last_plot = time.monotonic()
        self.plot_dirty = False
        progress = []
        for name,label in STAGES:
            jobs = self.plans.get(name, {})
            done = [r for r in self.results.values() if r['parent'] in jobs]
            progress.append(dict(label=label, planned=sum(len(j['grid']) for j in jobs.values()), complete=sum(r['status']=='complete' for r in done),
                                 failed=sum(r['status']!='complete' for r in done)))
        fit_phase = next((n for n in ('06-final-fits','02-effort','01-algorithms') if n in self.plans), '')
        ids = list(self.plans.get(fit_phase, {}))
        fits = [self.results[i] for i in ids if i in self.results and self.results[i]['status']=='complete']
        if fit_phase == '06-final-fits':
            fits = [r for r in fits if r['job']['kind']=='stock']
        best, rows = {}, []
        for r in fits:
            sm = r['job']['smoothing']
            best[sm] = min(r['objective'], best.get(sm, math.inf))
        for r in fits:
            j,p = r['job'],r['job']['profile']
            label = f'{p["opt"]}/{p["optad"]} | {p["pliter"]} | {p["lfsimaniter"]} | {p["ftol"]:g} | {p["moredetail"]}{p["moredetailad"]}'
            rows.append(dict(profile=str(profile_key(p)), label=label, smoothing=j['smoothing'],
                             gap=(r['objective']-best[j['smoothing']])/max(abs(best[j['smoothing']]),1)))
        current = dict(self.curves)
        for r in self.results.values():
            if r['parent'] in self.plans.get('05-smoothing',{}) and r['status']=='complete':
                key = (round(math.log10(r['job']['smoothing']),10),r['job']['rep'])
                current.setdefault(key,r)
        cvs = [dict(smoothing=r['job']['smoothing'],replicate=r['job']['rep']+1,score=r['score'])
               for r in current.values()]
        table(self.work / 'plot-progress.tsv', progress)
        table(self.work / 'plot-fits.tsv', rows)
        table(self.work / 'plot-cv.tsv', cvs)
        table(self.work / 'plot-state.tsv', [dict(fit_phase=fit_phase,replicates=self.a.cv_replicates,tolerance=self.a.cv_tolerance,
            status='Complete' if self.finished else 'Running', complete=len(self.results))])
        try:
            subprocess.run([self.rscript,str(self.work / 'summary.R'),str(self.work),self.config.stem,str(self.root)],
                           capture_output=True,text=True,check=True)
        except (OSError, subprocess.CalledProcessError) as error:
            self.plot_enabled = False
            print('Warning: live figures disabled; fitting continues.\n'+(getattr(error,'stderr',None) or str(error)),file=sys.stderr)

    def workflow(self):
        seed,grid = self.a.seed,self.a.grid
        anchors = sorted({min(grid,key=lambda sm:abs(math.log10(sm)-x)) for x in (0,-4)},reverse=True)
        screen = unique([profile(opt=i,optad=j,pliter=5,lfsimaniter=500,ftol=1e-6) for i in range(6) for j in (i,(i+1)%6)])
        r = self.compare('01-algorithms',screen,anchors,range(seed,seed+2))
        algorithms = rank_profiles(r)
        survivors = unique([rank_profiles(r)[0]] + [rank_profiles([v for v in r if v['job']['smoothing']==sm])[0] for sm in anchors])
        effort = []
        for p in survivors:
            base = changed(p,pliter=50,lfsimaniter=1500,ftol=1e-8)
            effort += [base,changed(base,ftol=1e-10),changed(base,moredetail=1),changed(base,moredetailad=1),
                       changed(base,moredetail=1,moredetailad=1),changed(base,pliter=100,lfsimaniter=5000)]
        r = self.compare('02-effort',effort,anchors[:1],range(seed+10,seed+12))
        finalists = rank_profiles(r)[:2]
        cv_profiles = [changed(finalists[0],optcvad=i,moredetailcvad=0) for i in range(6)]
        r = self.compare('03-cv-algorithms',cv_profiles,anchors[:1],range(seed+20,seed+22),'cv')
        cvbest = rank_profiles(r,cv=True)[0]
        r = self.compare('04-cv-effort',[cvbest,changed(cvbest,moredetailcvad=1),changed(cvbest,cviter=6),
                         changed(cvbest,moredetailcvad=1,cviter=6)],anchors[:1],range(seed+20,seed+22),'cv')
        selected = rank_profiles(r,cv=True)[0]
        self.polish = polish_methods([selected]+survivors+algorithms,selected['optcvad'])
        print('Chained optimizers: '+', '.join('/'.join(map(str,m)) for m in self.polish),flush=True)
        sm,checked = self.smoothing(changed(selected,ftol=min(selected['ftol'],1e-10)))
        selected = changed(selected,optcvad=checked['optcvad'])
        finalists = [changed(p,optcvad=selected['optcvad'],moredetailcvad=selected['moredetailcvad'],cviter=selected['cviter']) for p in finalists]
        existing = {(p['opt'],p['optad']) for p in finalists}
        finalists += [changed(selected,opt=p['opt'],optad=p['optad']) for p in survivors if (p['opt'],p['optad']) not in existing]
        refined = changed(selected,lfsimaniter=0,ftol=min(selected['ftol'],1e-12),
                          moredetail=0,moredetailad=0,moredetailcvad=0)
        self.batch('06-final-fits',[self.job(refined,sm,seed+300+rep,
            starts=(self.curves[round(math.log10(sm),10),rep]['state'],None),polish=self.polish)
            for rep in range(min(4,self.a.cv_replicates))])
        r = self.compare('06-final-fits',finalists,[sm],range(seed+200,seed+203),'stock')
        self.export(rank_profiles(r)[0],sm)

    def export(self, p, sm):
        final = self.plans['06-final-fits']
        observed = [r for r in self.results.values() if r['status']=='complete' and r['parent'] in final]
        stock = min((r for r in observed if r['job']['kind']=='stock' and r['job']['profile']==p),key=lambda r:r['objective'])
        observed = [r for r in observed if r['job']['kind']!='stock']
        best = min(observed,key=lambda r:r['objective'])
        table(self.work / 'trees.tsv',[dict(id=r['job']['id'],path=str(self.work/r['job']['id']/'result.tre'),objective=r['objective']) for r in observed])
        src = self.work / best['job']['id']
        check = subprocess.run([self.rscript,str(self.work/'final.R'),str(self.tree),str(src/'result.tre'),
            str(src/'fit.config'),str(self.work/'trees.tsv'),str(self.work)],capture_output=True,text=True)
        if check.returncode:
            raise RuntimeError('Final tree check failed:\n'+check.stderr)
        shutil.copyfile(src/'result.tre',self.root/'dated.tre')
        shutil.copyfile(self.tree,self.root/'input.tre')
        (self.root/'recommended.config').write_text(render_config((self.work/stock['job']['id']/'fit.config').read_text(),
            dict(treefile='input.tre',outfile='replayed.tre'),{}))
        self.finished = True
        self.plot(force=True)
        print(f'Finished: smoothing={sm:g}; objective={best["objective"]:g}; settings={p}',flush=True)
        print(f'Stock config checked: objective={stock["objective"]:g}',flush=True)
        print(check.stdout.strip(),flush=True)

    def run(self):
        self.root.mkdir(parents=True,exist_ok=False)
        began = time.monotonic()
        with tempfile.TemporaryDirectory(prefix='treepl-') as tmp:
            self.work = Path(tmp)
            (self.work/'summary.R').write_text(PLOT_R)
            (self.work/'final.R').write_text(FINAL_R)
            try:
                self.workflow()
            except BaseException:
                self.stop.set()
                raise
            finally:
                print(f'Elapsed: {(time.monotonic()-began)/60:.1f} min',flush=True)
        return 0


def main(argv=None):
    def interrupted(signum, frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM,interrupted)
    try:
        return Optimizer(parse_args(argv)).run()
    except KeyboardInterrupt:
        print('Interrupted.',file=sys.stderr)
        return 130
    except (ValueError,RuntimeError,OSError,KeyError) as error:
        print(f'Error: {error}',file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
