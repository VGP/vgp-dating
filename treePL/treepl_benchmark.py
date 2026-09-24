#!/usr/bin/env python3
"""Replicated randomCV, optimizer screening, deep searching, and final publication."""
import argparse
import concurrent.futures as futures
import csv
import fcntl
import hashlib
import io
import itertools
import json
import math
import os
from pathlib import Path
import random
import re
import shutil
import signal
import statistics
import subprocess
import sys
import tempfile
import threading
import time

ENGINE = 'vgp-randomcv-v1'
CANDIDATES = ((1, 3, 0, 0), (2, 3, 1, 1), (2, 3, 0, 0))
SCORE = re.compile(r'^chisq: \(([^)]+)\)\s*(\S+)')
OBJECTIVE = re.compile(r'^after opt calc:\s*(\S+)')
PARTIAL = re.compile(r'^\(chisq\):\s*([+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?|[+-]?(?:inf(?:inity)?|nan))\s*$', re.I)

# Embedded helpers keep this module independent of the retired benchmark/test code.
PLOT_INPUTS_R = r'''
suppressPackageStartupMessages(library(ape))
a <- commandArgs(TRUE)
t <- read.tree(a[1])
ann <- read.delim(a[2],comment.char='',stringsAsFactors=FALSE)
names(ann)[1] <- 'accession'
required <- c('accession','ScientificName','VGPLineage','Lineage','Superorder','AssemblyId')
missing <- setdiff(required,names(ann))
if(length(missing)) stop('Missing annotation columns: ',paste(missing,collapse=', '))
if(anyDuplicated(ann$accession)) stop('Duplicate annotation accessions.')
lookup <- match(t$tip.label,ann$accession)
if(a[4]=='astralpro.l6p1') {
  row <- which(!is.na(ann$AssemblyId) & ann$AssemblyId=='kxProAnne1')
  if(length(row)!=1L || ann$accession[row]!='GCA_040939525.1') stop('Ambiguous kxProAnne1 alias.')
  lookup[t$tip.label=='kxProAnne1'] <- row
}
if(anyNA(lookup)) stop('Missing tip annotations: ',paste(t$tip.label[is.na(lookup)],collapse=', '))
labels <- ann$ScientificName[lookup]
if(anyNA(labels) || any(!nzchar(trimws(labels)))) stop('Missing scientific names.')
labels <- gsub(' ','_',labels)
repeated <- duplicated(labels) | duplicated(labels,fromLast=TRUE)
labels[repeated] <- paste(labels[repeated],t$tip.label[repeated],sep='_')
if(anyDuplicated(labels)) stop('Scientific tip labels are not unique.')
invisible(png::readPNG(a[3]))
'''


VALIDATE_R = r'''
suppressPackageStartupMessages(library(ape))
a <- commandArgs(TRUE)
age_tolerance <- 0.001
check <- function(t) {
  if(!inherits(t,'phylo') || !is.rooted(t) || anyDuplicated(t$tip.label) ||
     is.null(t$edge.length) || any(!is.finite(t$edge.length)) || any(t$edge.length<0))
    stop('Expected one rooted tree, unique taxa, and finite nonnegative lengths.')
}
ref <- read.tree(a[1]); check(ref)
entries <- lapply(trimws(sub('#.*$','',readLines(a[2]))),function(x)
  strsplit(trimws(gsub('=',' ',x,fixed=TRUE)),'[[:space:]]+')[[1]])
pairs <- Filter(function(x) length(x)>0 && x[1]=='mrca',entries)
if(!length(pairs)) stop('No calibrations.')
n <- Ntip(ref)+ref$Nnode
lo <- rep(0,n); hi <- rep(Inf,n); hi[seq_len(Ntip(ref))] <- 0
for(p in pairs) {
  if(length(p)!=4 || !all(p[3:4] %in% ref$tip.label) || p[3]==p[4]) stop('Invalid defining taxa.')
  node <- getMRCA(ref,p[3:4])
  bounds <- vapply(c('min','max'),function(k) {
    v <- Filter(function(x) length(x)>1 && x[1]==k && x[2]==p[2],entries)
    if(length(v)!=1 || length(v[[1]])!=3) stop('Missing or duplicate bound.')
    as.numeric(v[[1]][3])
  },numeric(1))
  if(any(!is.finite(bounds)) || bounds[1]<0 || bounds[1]>bounds[2]) stop('Invalid bounds.')
  lo[node] <- max(lo[node],bounds[1]); hi[node] <- min(hi[node],bounds[2])
}
e <- reorder.phylo(ref,'postorder')$edge
for(i in seq_len(nrow(e))) lo[e[i,1]] <- max(lo[e[i,1]],lo[e[i,2]])
if(any(lo>hi)) stop('Calibration bounds are incompatible on this topology.')
if(a[3]=='-') {cat('Input valid:',Ntip(ref),'tips;',length(pairs),'calibrations\n'); quit()}
t <- read.tree(a[3]); check(t)
if(!isTRUE(all.equal.phylo(ref,t,use.edge.length=FALSE,use.tip.label=TRUE))) stop('Topology or taxa changed.')
d <- node.depth.edgelength(t); h <- max(d[seq_len(Ntip(t))]); ages <- h-d
if(h<=0 || diff(range(d[seq_len(Ntip(t))]))>age_tolerance) stop('Non-ultrametric dated tree.')
for(p in pairs) {
  node <- getMRCA(t,p[3:4])
  for(k in c('min','max')) {
    v <- Filter(function(x) length(x)>1 && x[1]==k && x[2]==p[2],entries)
    b <- as.numeric(v[[1]][3])
    if((k=='min' && ages[node]<b-age_tolerance) || (k=='max' && ages[node]>b+age_tolerance)) stop('Calibration violation.')
  }
}
cat('Dated tree valid: topology, ages, and calibration bounds.\n')
if(length(a)>=4) {
  keys<-function(t) {
    ch<-split(t$edge[,2],t$edge[,1]);memo<-vector('list',Ntip(t)+t$Nnode)
    descend<-function(n) {
      if(length(memo[[n]]))return(memo[[n]])
      memo[[n]]<<-if(n<=Ntip(t))t$tip.label[n] else sort(unlist(lapply(ch[[as.character(n)]],descend)))
      memo[[n]]
    }
    vapply(seq.int(Ntip(t)+1,Ntip(t)+t$Nnode),function(n)paste(descend(n),collapse='|'),character(1))
  }
  idx<-match(keys(ref),keys(t));if(anyNA(idx))stop('Node mapping failed.')
  write.table(data.frame(node=seq.int(Ntip(ref)+1,Ntip(ref)+ref$Nnode),age_ma=ages[Ntip(t)+idx]),a[4],sep='\t',quote=FALSE,row.names=FALSE)
}
'''

PLOT_R = r'''
a <- commandArgs(TRUE); root <- a[1]; title <- a[2]; target <- as.integer(a[3])
read <- function(n) {p<-file.path(root,n);if(file.exists(p)) read.delim(p,check.names=FALSE) else NULL}
s<-read('cv_summary.tsv');v<-read('cv_attempts.tsv');o<-read('optimizer_summary.tsv');comparison<-read('cv_comparison.tsv')
ink<-'#243746';blue<-'#227C9D';gold<-'#D59A35';red<-'#BA594A'
empty<-function(label){plot.new();text(.5,.5,label,col=ink)}
xx<-log10(s$smoothing); xr<-rev(range(xx))+c(.5,-.5)
boxwidth<-if(length(xx)>1) min(.55,.55*min(diff(sort(xx)))) else .55
ticks<-pretty(range(xx),n=8)
for(ext in c('png','pdf')) {
 dest<-file.path(root,paste0('progress.',ext));tmp<-paste0(dest,'.tmp')
 if(ext=='png') png(tmp,width=1800,height=1300,res=150) else pdf(tmp,width=12,height=8.67,useDingbats=FALSE)
 par(mfrow=c(2,2),oma=c(1,0,4,0),mar=c(5.5,6,2.5,1),mgp=c(4,.8,0),cex.axis=.85,cex.main=1.05,col=ink,col.axis=ink,col.lab=ink,fg=ink,las=1,bty='l')
 good<-if(!is.null(v)) v[v$status=='accepted' & is.finite(v$score) & v$score>0,,drop=FALSE] else NULL
 if(!is.null(good) && nrow(good)) {
  yr<-range(good$score);if(diff(yr)==0)yr<-yr*c(.9,1.1)
  plot(NA,log='y',xlim=xr,ylim=yr*c(.9,1.25),xaxt='n',xlab='Smoothing (log10)',ylab='Random-CV score (log scale)',main='CV medians and seed variation')
  set.seed(20260923)
  for(sm in sort(unique(good$smoothing),decreasing=TRUE)) {
   values<-sort(good$score[good$smoothing==sm]); bs<-boxplot.stats(values)
   # Suppress misleading, inverted notches in tiny or highly skewed samples.
   notch<-length(values)>=5 && bs$conf[1]>=bs$stats[2] && bs$conf[2]<=bs$stats[4]
   boxplot(values,at=log10(sm),add=TRUE,axes=FALSE,outline=FALSE,notch=notch,
           boxwex=boxwidth,col=adjustcolor(blue,.16),border=blue,lwd=1.3)
   points(log10(sm)+runif(length(values),-boxwidth*.32,boxwidth*.32),values,pch=16,col=adjustcolor(blue,.45),cex=.55)
  }
  axis(1,at=ticks);z<-s[is.finite(s$median)&s$median>0,,drop=FALSE]
  lines(log10(z$smoothing),z$median,col=ink,lwd=1.4);points(log10(z$smoothing),z$median,pch=18,col=ink,cex=.8)
  if(!is.null(comparison)) {
   chosen<-comparison[tolower(comparison$selected)=='true',,drop=FALSE]
   if(nrow(chosen))points(log10(chosen$smoothing),chosen$median,pch=21,bg=gold,col=ink,cex=1.5,lwd=1.3)
  }
  legend('topleft',c('Accepted seed','Median','Selected smoothing'),pch=c(16,18,21),col=c(blue,ink,ink),pt.bg=c(NA,NA,gold),bty='n',cex=.7)
 } else empty('Waiting for accepted CV scores')
 barplot(rbind(s$accepted,s$rejected),ylim=c(0,max(1,s$attempts)*1.3),names.arg=format(s$smoothing,scientific=TRUE,trim=TRUE),col=c(blue,red),border=NA,las=2,cex.names=.75,ylab='Evaluations',main='Accepted and rejected / failed attempts')
 legend('topleft',c('Accepted','Rejected / failed'),fill=c(blue,red),bty='n',cex=.85)
 if(!is.null(o) && any(is.finite(o$median))) {
  o$gap<-NA_real_
  for(sm in unique(o$smoothing)){ii<-o$smoothing==sm & is.finite(o$median);if(any(ii)){best<-min(o$median[ii]);o$gap[ii]<-100*(o$median[ii]-best)/max(abs(best),1e-12)}}
  yr<-range(c(0,o$gap),na.rm=TRUE);if(diff(yr)==0)yr<-c(0,.01)
  plot(NA,xlim=xr,ylim=yr,xaxt='n',xlab='Smoothing (log10)',ylab='Median objective above best (%)',main='Short optimizer screen');axis(1,at=ticks)
  cand<-unique(o$candidate);cols<-c(blue,gold,red)
  for(j in seq_along(cand)){z<-o[o$candidate==cand[j],];lines(log10(z$smoothing),z$gap,type='b',pch=15+j,col=cols[j],lwd=1.8)}
  legend('topleft',cand,col=cols,pch=seq_along(cand)+15,bty='n',cex=.85)
 } else empty('Optimizer screen pending')
 if(!is.null(v) && nrow(v)) {
  plot(log10(v$smoothing),v$seconds,xlim=xr,pch=16,col=ifelse(v$status=='accepted',blue,red),xaxt='n',xlab='Smoothing (log10)',ylab='Seconds per attempt',main='Runtime, including terminated attempts');axis(1,at=ticks)
 } else empty('Waiting for completed attempts')
 mtext(paste(title,'| Replicated randomCV'),outer=TRUE,line=2,font=2,cex=1.45,col=ink)
 mtext(paste(target,'accepted seeds per value | Updated',format(Sys.time(),'%Y-%m-%d %H:%M:%S')),outer=TRUE,line=.4,cex=.85,col=ink)
 dev.off();if(!file.rename(tmp,dest))stop('Cannot publish graphic')
}
'''


def atomic(path, text):
    path = Path(path)
    tmp = path.with_name(path.name + '.tmp')
    tmp.write_text(text)
    os.replace(tmp, path)


def save(path, data):
    atomic(path, json.dumps(data, indent=2, allow_nan=False) + '\n')


def table(path, rows):
    if rows:
        out = io.StringIO()
        writer = csv.DictWriter(out, fieldnames=list(rows[0]), delimiter='\t')
        writer.writeheader()
        writer.writerows(rows)
        atomic(path, out.getvalue())


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


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
            raise ValueError(f'Duplicate config setting: {key}')
        result[key] = value.strip() if sep else True
    return result


def calibration_check(text, master, topology):
    column = 'node_' + topology.replace('.', '_')
    with master.open() as handle:
        reader = csv.DictReader(handle)
        if column not in reader.fieldnames:
            raise ValueError(f'Master lacks {column}')
        rows = list(reader)
    if len({r['calibration_id'] for r in rows}) != len(rows):
        raise ValueError('Duplicate master calibration IDs')
    expected = {r['node_name']: r for r in rows if r[column].strip()}
    if not expected or len(expected) != sum(bool(r[column].strip()) for r in rows):
        raise ValueError('Empty or duplicate calibration names in master')
    actual = {key: {} for key in ('mrca', 'min', 'max')}
    for raw in text.splitlines():
        parts = raw.split('#', 1)[0].replace('=', ' ').split()
        if not parts or parts[0] not in actual:
            continue
        key = parts[0]
        if len(parts) < 3 or parts[1] in actual[key]:
            raise ValueError('Malformed or duplicate calibration')
        actual[key][parts[1]] = parts[2:]
    for key, values in actual.items():
        if set(values) != set(expected):
            raise ValueError(f'{key} calibration names differ from master')
        for name, row in expected.items():
            v = values[name]
            if key == 'mrca':
                valid = len(v) == 2 and set(v) == {row['taxon1_accession'], row['taxon2_accession']}
            else:
                valid = len(v) == 1 and math.isfinite(float(v[0])) and float(v[0]) == float(row[key + '_ma'])
            if not valid:
                raise ValueError(f'{name} {key} differs from master')


def smoothing_text(value):
    """Readable smoothing values, retaining 12 significant digits for custom grids."""
    mantissa, separator, exponent = format(value, '.12g').partition('e')
    return f'{mantissa}e{int(exponent)}' if separator else mantissa


def config_text(original, updates, flags):
    removed = {
        'prime', 'thorough', 'cv', 'randomcv', 'cvstart', 'cvstop', 'cvmultstep',
        'cvoutfile', 'randomcviter', 'randomcvsamp',
    }
    replacements = {key: f'{key} = {value}' for key,value in updates.items()}
    replacements.update({key: key if enabled else '#'+key for key,enabled in flags.items()})
    replacements.update(prime='#prime', thorough='#thorough')
    lines, seen = [], set()
    for raw in original.splitlines():
        key = raw.lstrip().lstrip('#').split('#', 1)[0].split('=', 1)[0].strip()
        if key in replacements:
            if key not in seen:
                suffix = ''
                if not raw.lstrip().startswith('#') and '#' in raw:
                    suffix = ' #' + raw.split('#',1)[1]
                lines.append(replacements[key]+suffix)
                seen.add(key)
        elif key not in removed:
            lines.append(raw)
    # New controls belong above the calibration block, never after its ages.
    for key,value in replacements.items():
        if key in seen:
            continue
        heading = '# Optimizers' if key not in flags and key not in ('prime','thorough') else '# Optional modes'
        position = next((i for i,line in enumerate(lines) if line.strip()==heading), None)
        if position is None:
            position = next((i for i,line in enumerate(lines) if line.strip() in ('# Calibrations','# BEGIN MASTER CALIBRATIONS') or line.lstrip().startswith('mrca')),len(lines))
        lines.insert(position,value)
    return '\n'.join(lines) + '\n'


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


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('config', type=Path)
    grid = p.add_mutually_exclusive_group()
    grid.add_argument('--smoothing-values', help='comma-separated positive values')
    grid.add_argument('--smoothing-range', nargs=3, metavar=('HIGH', 'LOW', 'COUNT'))
    p.add_argument('--seed-count', type=int, default=64, help='accepted CV seeds per value (64)')
    p.add_argument('--screen-seeds', type=int, default=3, help='shared seeds per optimizer screen (3)')
    p.add_argument('--seed', type=int, default=20260922, help='recorded seed-generator seed')
    p.add_argument('--jobs', type=int, default=8)
    p.add_argument('--threads', type=int, default=2)
    p.add_argument('--pliter', type=int, default=50)
    p.add_argument('--cviter', type=int, default=3)
    p.add_argument('--optimizer-seeds', type=int, default=3, help='shared seeds for the post-CV 144-configuration screen (3)')
    p.add_argument('--optimizer-pliter', type=int, default=200, help='post-CV optimizer screening budget (200)')
    p.add_argument('--deep-seeds', type=int, default=50, help='shared seed attempts per retained configuration (50)')
    p.add_argument('--deep-pliter', type=int, default=2500, help='iteration budget for deep seed fits (2500)')
    p.add_argument('--deep-configurations', type=int, default=2, help='maximum configurations for deep searching (2)')
    p.add_argument('--fallback-ceiling', type=float, default=1e12)
    p.add_argument('--outlier-factor', type=float, default=100)
    p.add_argument('--master', type=Path, default=Path(__file__).resolve().parent.parent/'calibrations/master_calibrations.csv')
    p.add_argument('--output', type=Path, help='default: CONFIG_DIRECTORY/generated/randomcv')
    p.add_argument('--keep-work', action='store_true', help='retain per-fit logs/configs/trees')
    p.add_argument('--dry-run', action='store_true', help='validate inputs and print workload; no fits or output deletion')
    a = p.parse_args()
    for name in ('seed_count', 'screen_seeds', 'jobs', 'threads', 'pliter', 'cviter', 'optimizer_seeds', 'optimizer_pliter', 'deep_seeds', 'deep_pliter', 'deep_configurations'):
        if getattr(a, name) < 1:
            p.error(f'{name.replace("_", "-")} must be positive')
    try:
        if a.smoothing_values:
            values = [float(x) for x in a.smoothing_values.split(',')]
        else:
            high, low, count = a.smoothing_range or ('1e4', '1e-10', '15')
            high, low, count = float(high), float(low), int(count)
            if not (math.isfinite(high) and math.isfinite(low) and high > low > 0 and count >= 2):
                raise ValueError('Range needs finite HIGH > LOW > 0 and COUNT >= 2')
            values = [10 ** (math.log10(high) + i*(math.log10(low)-math.log10(high))/(count-1)) for i in range(count)]
        if not values or any(not math.isfinite(v) or v <= 0 for v in values) or len(set(values)) != len(values):
            raise ValueError('Smoothing values must be finite, positive, and unique')
        a.smoothing = sorted(values, reverse=True)
    except (ValueError, OverflowError) as error:
        p.error(str(error))
    if not math.isfinite(a.fallback_ceiling) or a.fallback_ceiling <= 0 or not math.isfinite(a.outlier_factor) or a.outlier_factor <= 1:
        p.error('Invalid outlier thresholds')
    return a


def choose_smoothing(points, attempts):
    """Select the lowest median; retain boxplot summaries only as diagnostics."""
    eligible = [p for p in points if p['status']=='complete']
    if not eligible:
        return None, []
    minimum = min(eligible,key=lambda p:(p['median'],-p['smoothing']))
    samples = {p['smoothing']: sorted(r['score'] for r in attempts
               if r['status']=='accepted' and r['smoothing']==p['smoothing']) for p in eligible}
    comparisons = []
    for p in sorted(eligible,key=lambda p:p['smoothing'],reverse=True):
        values = samples[p['smoothing']]; n = len(values)
        # Tukey hinges match R boxplot.stats/fivenum, including odd sample sizes.
        q1 = statistics.median(values[:(n+1)//2])
        q3 = statistics.median(values[n//2:])
        halfwidth = 1.58*(q3-q1)/math.sqrt(n)
        comparisons.append(dict(smoothing=p['smoothing'],accepted=n,median=p['median'],
                                q1=q1,q3=q3,notch_low=p['median']-halfwidth,notch_high=p['median']+halfwidth,
                                raw_minimum=p is minimum,selected=p is minimum))
    return minimum, comparisons


class RandomCV:
    """One independent pipeline module; run() returns a smoothing selection."""

    def __init__(self, args):
        self.a = args
        self.config = args.config.resolve()
        self.master = args.master.resolve()
        self.original = self.config.read_text()
        self.options = settings(self.original)
        self.tree = (self.config.parent / self.options['treefile']).resolve()
        output = args.output or self.config.parent/'generated/randomcv'
        if output.is_symlink():
            raise ValueError('Output directory must not itself be a symlink')
        self.root = output.resolve()
        self.binary = shutil.which('treePL')
        self.rscript = shutil.which('Rscript')
        if not self.binary or not self.rscript:
            raise RuntimeError('treePL and Rscript (with ape) are required')
        self.stop = threading.Event()
        self.print_lock = threading.Lock()
        self.log_path = None
        self.rng = random.Random(args.seed)
        self.used_seeds = set()
        self.attempts, self.optimizer_fits, self.optimizer_summaries = [], [], []
        self.points = [dict(smoothing=sm, accepted=0, attempts=0, rejected=0,
                            median=None, minimum=None, maximum=None, status='pending', candidate='')
                       for sm in args.smoothing]
        self.started = time.monotonic()

    def log(self, message):
        with self.print_lock:
            line = time.strftime('[%Y-%m-%d %H:%M:%S] ') + message
            print(line, flush=True)
            if self.log_path:
                with self.log_path.open('a') as handle:
                    handle.write(line + '\n')

    def next_seed(self):
        while True:
            seed = self.rng.randrange(1, 2147483648)
            if seed not in self.used_seeds:
                self.used_seeds.add(seed)
                return seed

    def write_status(self, status, stage, published=False):
        generated = self.config.parent/'generated'
        generated.mkdir(parents=True,exist_ok=True)
        atomic(generated/'final_run_status.txt',f'status={status}\nstage={stage}\nconfig={self.config.name}\npublished={str(published).lower()}\n')

    def checked(self, command, logfile, cwd=None):
        with logfile.open('w') as out:
            proc = subprocess.Popen(command, cwd=cwd, stdout=out, stderr=subprocess.STDOUT, start_new_session=True)
            try:
                while proc.poll() is None:
                    if self.stop.wait(.2):
                        raise InterruptedError('Interrupted')
            finally:
                terminate(proc)
        if proc.returncode:
            raise RuntimeError(f'Command failed: {logfile.read_text(errors="replace")[-2000:]}')

    def preflight(self):
        calibration_check(self.original, self.master, self.config.stem)
        n = float(self.options.get('numsites', 0))
        if not math.isfinite(n) or n <= 0 or n != int(n):
            raise ValueError('numsites must be a positive integer')
        if 'log_pen' in self.options:
            raise ValueError('log_pen is not supported: the installed build has an objective/gradient mismatch')
        self.hashes = {str(p): digest(p) for p in (self.config, self.tree, self.master, Path(self.binary))}
        with tempfile.TemporaryDirectory(prefix='vgp-cv-preflight-') as tmp:
            tmp = Path(tmp)
            (tmp/'validate.R').write_text(VALIDATE_R)
            (tmp/'input.config').write_text(self.original)
            self.checked([self.rscript, str(tmp/'validate.R'), str(self.tree), str(tmp/'input.config'), '-'], tmp/'validation.log')
            self.validation = (tmp/'validation.log').read_text()
            self.checked([self.rscript,'-e', 'p<-c("ape","rphylopic","phytools","plotrix","png"); missing<-p[!vapply(p,requireNamespace,logical(1),quietly=TRUE)]; if(length(missing))stop("Missing plotting packages: ",paste(missing,collapse=", "))'],tmp/'plot_dependencies.log')
            (tmp/'plot_inputs.R').write_text(PLOT_INPUTS_R)
            self.checked([self.rscript,str(tmp/'plot_inputs.R'),str(self.tree),
                          str(self.config.parent/'../../trees/annotations.tsv'),
                          str(self.config.parent/'../vgp.png'),self.config.stem],tmp/'plot_inputs.log')
        self.topology_plot = self.config.parent/(self.config.stem+'.treePL.R')
        self.dated_plot = Path(__file__).resolve().parent/'plot_dated_tree.R'
        if not self.topology_plot.is_file() or not self.dated_plot.is_file():
            raise ValueError('Missing topology-specific or shared dated-tree plotting script')
        generated = self.config.parent/'generated'
        if generated.is_symlink():
            raise ValueError('Production generated directory must not be a symlink')
        self.log(self.validation.strip())
        self.log(f'Plan: {len(self.points)} smoothing values; {len(CANDIDATES)*self.a.screen_seeds} optimizer fits/value; '
                 f'{self.a.seed_count} accepted CV seeds/value; {self.a.jobs} jobs x {self.a.threads} threads; '
                 f'pliter={self.a.pliter}, cviter={self.a.cviter}, thorough=off')
        self.log('Grid: ' + ', '.join(f'{p["smoothing"]:g}' for p in self.points))
        self.log(f'After complete CV: 144 configurations x {self.a.optimizer_seeds} shared seeds '
                 f'= {144*self.a.optimizer_seeds} full-tree fits at the selected smoothing; '
                 f'pliter={self.a.optimizer_pliter}, thorough=off')
        self.log(f'Deep search: up to {self.a.deep_configurations} configurations x {self.a.deep_seeds} shared seeds '
                 f'= at most {self.a.deep_configurations*self.a.deep_seeds} fits; pliter={self.a.deep_pliter}, thorough=off')
        self.log('Final stage: one standalone confirmation, publish the better validated tree/config, then generate dated-tree graphics')
        self.log(f'Output: {self.root}; only this benchmark\'s previous output is replaced')
        if self.a.jobs*self.a.threads > (os.cpu_count() or 1):
            self.log(f'Note: requested {self.a.jobs*self.a.threads} threads exceeds {os.cpu_count()} logical CPUs; keeping explicit allocation')

    def prepare(self):
        if self.root == self.config.parent or self.root in self.config.parents or any(self.root == Path(p) or self.root in Path(p).parents for p in (*self.hashes, str(Path(__file__).resolve()))):
            raise ValueError('Unsafe output path contains an input')
        if self.root.exists():
            marker = self.root/'manifest.json'
            if not marker.is_file() or json.loads(marker.read_text()).get('engine') != ENGINE:
                raise ValueError(f'Refusing to delete an unrelated directory: {self.root}')
            shutil.rmtree(self.root)
        self.root.mkdir(parents=True)
        self.log_path = self.root/'progress.log'
        (self.root/'input.config').write_text(self.original)
        (self.root/'input.tre').write_bytes(self.tree.read_bytes())
        shutil.copyfile(self.master, self.root/'master_calibrations.csv')
        shutil.copyfile(Path(__file__), self.root/'benchmark.py')
        (self.root/'validate.R').write_text(VALIDATE_R)
        (self.root/'plot.R').write_text(PLOT_R)
        (self.root/'input_validation.log').write_text(self.validation)
        self.manifest = dict(engine=ENGINE, status='running', stage='cv', config=str(self.config), input_hashes=self.hashes,
                             script_sha256=digest(Path(__file__)), options={k:str(v) if isinstance(v,Path) else v for k,v in vars(self.a).items()},
                             candidates=CANDIDATES, cpu_count=os.cpu_count(),
                             randomcv='Installed treePL uses 10 groups of 10% tips. Scores are not on the full-CV scale.',
                             caveats=['Rejection is heuristic and cannot detect a bad majority; replacements condition the sampled distribution.',
                                      'Thread scheduling can affect random draws even with recorded seeds.'])
        save(self.root/'manifest.json', self.manifest)
        self.write_status('running','cv')
        self.log('Starting replicated randomCV from input snapshots; the final stage updates the production config')
        self.reports()

    def fit(self, index, candidate, seed, stage, ceiling=None, pliter=None):
        if self.stop.is_set():
            raise InterruptedError('Interrupted')
        sm = self.a.smoothing[index]
        tag = '-'.join(map(str, candidate))
        fit_id = f'{stage}/s{index:02d}/{tag}_seed-{seed}'
        directory = self.root/'.work'/fit_id
        directory.mkdir(parents=True)
        pliter = self.a.pliter if pliter is None else pliter
        updates = dict(treefile=str(self.root/'input.tre'), outfile='result.tre', seed=seed,
                       smooth=smoothing_text(sm), pliter=pliter, cviter=self.a.cviter,
                       nthreads=self.a.threads, opt=candidate[0], optad=candidate[1])
        flags = dict(moredetail=bool(candidate[2]), moredetailad=bool(candidate[3]))
        cv = stage == 'cv'
        if cv:
            updates.update(cvstart=smoothing_text(sm), cvstop=smoothing_text(sm), cvmultstep=.1, cvoutfile='cv.out')
            flags.update(cv=True, randomcv=True)
        config = config_text(self.original, updates, flags)
        (directory/'fit.config').write_text(config)
        row = dict(smoothing=sm, seed=seed, candidate=tag, stage=stage, status='failed',
                   pliter=pliter, threads=self.a.threads, thorough=False,
                   objective=None, score=None, seconds=None, groups=0, threshold=ceiling,
                   max_partial_score=None, reason='', fit_id=fit_id)
        began = time.monotonic()
        self.log(f'{stage} smooth={sm:g} {tag} seed={seed}: starting')
        scores, objective, groups, negative_returns = [], None, 0, 0
        random_mode, post_cv, rejected, tail = False, False, '', ''
        next_report = began + 30
        try:
            with (directory/'run.log').open('w') as out, (directory/'run.log').open(errors='replace') as incoming:
                proc = subprocess.Popen([self.binary, 'fit.config'], cwd=directory, stdout=out,
                                        stderr=subprocess.STDOUT, start_new_session=True)
                pending = ''
                try:
                    while True:
                        ended = proc.poll() is not None
                        chunk = incoming.read()
                        tail = (tail + chunk)[-4000:]
                        pending += chunk
                        lines = pending.split('\n'); pending = lines.pop()
                        if ended and pending:
                            lines.append(pending); pending = ''
                        for line in lines:
                            if 'conducting RANDOM SUBSAMPLE' in line:
                                random_mode = True
                            # OpenMP workers interleave stdout. Progress is approximate;
                            # only the serial final score/file establishes completion.
                            groups += len(re.findall(r'(?<![\w])cv:\s*', line))
                            if re.match(r'^result:\s*-\d+', line):
                                negative_returns += 1
                            match = OBJECTIVE.match(line)
                            if match:
                                objective = float(match[1])
                            match = SCORE.match(line)
                            if match:
                                scores.append((float(match[1]), float(match[2])))
                            if scores and line.startswith('smoothing:'):
                                post_cv = True
                            match = PARTIAL.match(line) or SCORE.match(line)
                            if cv and match:
                                value = float(match[len(match.groups())])
                                if not math.isfinite(value) or value < 0:
                                    rejected = 'nonfinite_or_negative_score'
                                else:
                                    row['max_partial_score'] = max(row['max_partial_score'] or 0, value)
                                    if value > ceiling:
                                        rejected = 'score_above_threshold'
                        if cv and rejected:
                            row.update(status='rejected', reason=rejected)
                            break
                        if cv and scores and (post_cv or ended):
                            saved = [SCORE.match(line) for line in (directory/'cv.out').read_text().splitlines()] if (directory/'cv.out').exists() else []
                            saved = [(float(m[1]), float(m[2])) for m in saved if m]
                            if len(scores)!=1 or len(saved)!=1 or not random_mode:
                                raise ValueError('Unexpected randomCV mode or score count')
                            if any(not math.isclose(x,sm,rel_tol=1e-5) for x,y in scores+saved) or not math.isfinite(saved[0][1]) or not math.isclose(scores[0][1],saved[0][1],rel_tol=5e-6,abs_tol=1e-12):
                                raise ValueError('CV log and saved score mismatch')
                            if ended and proc.returncode:
                                raise ValueError(f'treePL exited {proc.returncode}')
                            row.update(status='accepted', score=scores[0][1])
                            break
                        if ended:
                            if proc.returncode:
                                raise ValueError(f'treePL exited {proc.returncode}')
                            if cv:
                                raise ValueError('Exited without a complete CV score')
                            if objective is None or not math.isfinite(objective) or objective < 0 or not (directory/'result.tre').is_file():
                                raise ValueError('Missing valid objective or dated tree')
                            command = [self.rscript, str(self.root/'validate.R'), str(self.root/'input.tre'),
                                       str(directory/'fit.config'), str(directory/'result.tre')]
                            if stage in ('deep_seed_search','final_confirmation'):
                                command.append(str(directory/'ages.tsv'))
                            self.checked(command, directory/'validation.log')
                            row.update(status='complete', objective=objective)
                            break
                        if self.stop.wait(.25):
                            raise InterruptedError('Interrupted')
                        if time.monotonic() >= next_report:
                            activity = f', approximately {groups}/10 groups reported' if cv else ''
                            self.log(f'{stage} smooth={sm:g} seed={seed}: running {time.monotonic()-began:.0f}s{activity}')
                            next_report = time.monotonic()+30
                finally:
                    terminate(proc)
        except OSError:
            # Infrastructure failures and interruptions must not become replacement seeds.
            self.stop.set()
            raise
        except (ValueError, RuntimeError) as error:
            row.update(status='failed', reason=str(error))
        row.update(seconds=round(time.monotonic()-began,3), groups=groups)
        record = dict(row, config=config, negative_returns=negative_returns,
                      raw_scores=[(str(x),str(y)) for x,y in scores], log_tail=tail if row['status'] not in ('accepted','complete') else '')
        validation = directory/'validation.log'
        if validation.exists():
            record['validation'] = validation.read_text()
        if row['status']=='complete':
            record['dated_tree'] = (directory/'result.tre').read_text()
        if stage in ('deep_seed_search','final_confirmation') and row['status']=='complete':
            with (directory/'ages.tsv').open() as handle:
                record['node_ages'] = {r['node']:float(r['age_ma']) for r in csv.DictReader(handle,delimiter='\t')}
        save(directory/'result.json', record)
        self.log(f'{stage} smooth={sm:g} seed={seed}: {row["status"]}; '
                 f'{"score" if cv else "objective"}={row["score"] if cv else row["objective"]}; {row["seconds"]:.1f}s {row["reason"]}')
        return row

    def batch(self, pool, jobs):
        pending = {pool.submit(self.fit, *job) for job in jobs}
        results = []
        try:
            while pending:
                done, pending = futures.wait(pending, timeout=1, return_when=futures.FIRST_COMPLETED)
                if self.stop.is_set():
                    raise InterruptedError('Interrupted')
                for future in done:
                    row = future.result()
                    results.append(row)
                    target = self.attempts if row['stage']=='cv' else self.optimizer_fits
                    target.append(row)
                    table(self.root/('cv_attempts.tsv' if row['stage']=='cv' else 'optimizer_fits.tsv'), target)
        except BaseException:
            self.stop.set()
            for future in pending:
                future.cancel()
            raise
        return results

    def reports(self):
        table(self.root/'cv_attempts.tsv', self.attempts)
        table(self.root/'optimizer_summary.tsv', self.optimizer_summaries)
        table(self.root/'cv_summary.tsv', self.points)
        try:
            self.checked([self.rscript, str(self.root/'plot.R'), str(self.root), self.config.stem, str(self.a.seed_count)], self.root/'plotting.log')
        except (RuntimeError, OSError) as error:
            self.log(f'Plot warning: {error}')

    def optimizer_screen(self, pool, index):
        seeds = [self.next_seed() for _ in range(self.a.screen_seeds)]
        rows = self.batch(pool, [(index,c,s,'optimizer') for c in CANDIDATES for s in seeds])
        summaries = []
        for c in CANDIDATES:
            tag = '-'.join(map(str,c))
            fits = [r for r in rows if r['candidate']==tag and r['status']=='complete']
            values = [r['objective'] for r in fits]
            summaries.append(dict(smoothing=self.a.smoothing[index], candidate=tag, usable=len(values)==len(seeds),
                                  median=statistics.median(values) if values else None, worst=max(values) if values else None,
                                  seconds=sum(r['seconds'] for r in fits), selected=False))
        eligible = [r for r in summaries if r['usable']]
        # Preserve the diagnostic's printed-precision tie handling.
        for field in ('median','worst'):
            if eligible:
                best = min(r[field] for r in eligible)
                eligible = [r for r in eligible if r[field]-best <= max(abs(best)*1e-6,1e-8)]
        chosen = min(eligible,key=lambda r:(r['seconds'],r['candidate'])) if eligible else None
        if chosen:
            chosen['selected'] = True
            self.log(f'Optimizer winner smooth={self.a.smoothing[index]:g}: {chosen["candidate"]}; median objective={chosen["median"]}')
        self.optimizer_summaries.extend(summaries)
        return tuple(map(int,chosen['candidate'].split('-'))) if chosen else None

    def sample_value(self, pool, index, candidate):
        point = self.points[index]
        point.update(status='running', candidate='-'.join(map(str,candidate)))
        rows = []
        self.reports()
        pending = set()

        def refill():
            kept = [r for r in rows if r['status']=='accepted']
            ceiling = statistics.median(r['score'] for r in kept)*self.a.outlier_factor if len(kept)>=3 else self.a.fallback_ceiling
            if not math.isfinite(ceiling):
                ceiling = sys.float_info.max
            # Reserve one target slot for each in-flight attempt: never oversample.
            available = min(self.a.jobs-len(pending),self.a.seed_count-len(kept)-len(pending))
            for _ in range(available):
                pending.add(pool.submit(self.fit,index,candidate,self.next_seed(),'cv',ceiling))

        try:
            refill()
            while pending:
                completed, pending = futures.wait(pending,timeout=1,return_when=futures.FIRST_COMPLETED)
                if self.stop.is_set():
                    raise InterruptedError('Interrupted')
                if not completed:
                    continue
                for future in completed:
                    row = future.result()
                    rows.append(row)
                    self.attempts.append(row)
                kept = [r for r in rows if r['status']=='accepted']
                if len(kept)>=3:
                    threshold = statistics.median(r['score'] for r in kept)*self.a.outlier_factor
                    for r in kept:
                        if r['score']>threshold:
                            r.update(status='rejected', reason='completed_score_above_updated_threshold', threshold=threshold)
                            path = self.root/'.work'/r['fit_id']/'result.json'
                            record = json.loads(path.read_text())
                            record.update(r)
                            save(path,record)
                values = [r['score'] for r in rows if r['status']=='accepted']
                point.update(accepted=len(values), attempts=len(rows), rejected=len(rows)-len(values),
                             median=statistics.median(values) if values else None,
                             minimum=min(values) if values else None, maximum=max(values) if values else None)
                # Launch replacements before plotting/reporting so free workers stay busy.
                refill()
                done = sum(p['accepted'] for p in self.points)
                total = len(self.points)*self.a.seed_count
                elapsed = time.monotonic()-self.started
                eta = f'{elapsed*(total-done)/done/60:.0f} min' if done else 'estimating'
                self.log(f'CV smooth={point["smoothing"]:g}: {len(values)}/{self.a.seed_count} accepted; '
                         f'{point["rejected"]} rejected/failed; {len(pending)} in flight; '
                         f'total={done}/{total}; provisional ETA={eta}')
                self.reports()
        except BaseException:
            self.stop.set()
            for future in pending:
                future.cancel()
            raise
        point['status'] = 'complete'
        self.reports()

    def consolidate(self, rows=None, destination=None):
        records = []
        for row in (self.optimizer_fits+self.attempts if rows is None else rows):
            directory = self.root/'.work'/row['fit_id']
            record = json.loads((directory/'result.json').read_text())
            record.update(row)  # Includes retrospective outlier decisions.
            records.append(record)
        atomic(destination or self.root/'evaluations.jsonl', ''.join(json.dumps(r,allow_nan=False)+'\n' for r in records))
        if not self.a.keep_work and (self.root/'.work').exists():
            shutil.rmtree(self.root/'.work')

    def run(self):
        with futures.ThreadPoolExecutor(max_workers=self.a.jobs) as pool:
            for index, point in enumerate(self.points):
                candidate = self.optimizer_screen(pool,index)
                if candidate is None:
                    point['status'] = 'optimizer_failed'
                    self.reports()
                    continue
                self.sample_value(pool,index,candidate)
        if any(digest(Path(p))!=h for p,h in self.hashes.items()):
            raise RuntimeError('Source input or executable changed during the run; results not selected')
        eligible = [p for p in self.points if p['status']=='complete']
        chosen, comparisons = choose_smoothing(self.points,self.attempts)
        complete = len(eligible)==len(self.points)
        selection = dict(status='complete' if complete else 'incomplete',
                         smoothing=chosen['smoothing'] if chosen else None,
                         median_cv=chosen['median'] if chosen else None,
                         candidate=chosen['candidate'] if chosen else None,
                         boundary=bool(chosen and chosen['smoothing'] in (self.a.smoothing[0],self.a.smoothing[-1])),
                         raw_minimum_smoothing=chosen['smoothing'] if chosen else None,
                         raw_minimum_median=chosen['median'] if chosen else None,
                         rule='Lowest median accepted CV score; exact ties favor higher smoothing.',
                         notch_rule='median +/- 1.58 IQR/sqrt(n), using Tukey hinges',
                         statistical_caveat='Notches are visual diagnostics only and do not affect selection.',
                         provisional=not complete, production_config_updated=False)
        table(self.root/'cv_comparison.tsv',comparisons)
        save(self.root/'selection.json',selection)
        self.reports()
        self.consolidate()
        self.manifest.update(status=selection['status'], seconds=round(time.monotonic()-self.started,2), production_unchanged=True)
        save(self.root/'manifest.json',self.manifest)
        self.log(f'CV finished: {selection["status"]}; smoothing={selection["smoothing"]}; median CV={selection["median_cv"]}'
                 + ('; boundary winner (flag only)' if selection['boundary'] else ''))
        self.log(f'Observed minimum: smoothing={selection["raw_minimum_smoothing"]}; median CV={selection["raw_minimum_median"]}; selection rule: {selection["rule"]}')
        return selection


OPTIMIZER_PLOT_R = r'''
a<-commandArgs(TRUE);root<-a[1];title<-a[2]
s<-read.delim(file.path(root,'summary.tsv'),check.names=FALSE)
s$usable<-tolower(s$usable)=='true';s$selected_for_deep<-tolower(s$selected_for_deep)=='true'
parts<-strsplit(s$candidate,'-',fixed=TRUE)
s$opt<-vapply(parts,function(x)as.integer(x[1]),integer(1))
s$optad<-vapply(parts,function(x)as.integer(x[2]),integer(1))
s$detail<-vapply(parts,function(x)paste0(x[3],x[4]),character(1))
good<-s$usable & is.finite(s$median)
best<-if(any(good)) min(s$median[good]) else NA_real_
gap<-rep(NA_real_,nrow(s));if(is.finite(best)) gap[good]<-100*pmax(0,s$median[good]-best)/max(abs(best),1e-12)
colors<-colorRampPalette(c('#EFF5F2','#75AFAD','#227C9D','#23394B'))(100)
hi<-max(c(0,log10(1+gap)),na.rm=TRUE);if(hi==0) hi<-1
ink<-'#243746'
for(ext in c('png','pdf')) {
 dest<-file.path(root,paste0('optimizer_screen.',ext));tmp<-paste0(dest,'.tmp')
 if(ext=='png')png(tmp,width=1800,height=1450,res=150) else pdf(tmp,width=12,height=9.67,useDingbats=FALSE)
 par(mfrow=c(2,2),mar=c(4.5,4.5,3,1),mgp=c(2.5,.7,0),oma=c(2,0,4,0),las=1,col=ink,col.axis=ink,col.lab=ink)
 for(bits in c('00','01','10','11')) {
  z<-which(s$detail==bits)
  plot(NA,xlim=c(-.5,5.5),ylim=c(-.5,5.5),xaxs='i',yaxs='i',axes=FALSE,xlab='opt',ylab='optad',main=paste('Detail flags',bits))
  axis(1,at=0:5);axis(2,at=0:5)
  for(i in z) {
   shade<-if(is.finite(gap[i])) colors[1+min(99,floor(99*log10(1+gap[i])/hi))] else if(s$completed[i]==s$requested[i]) '#EBCAC3' else '#E7EAEC'
   rect(s$opt[i]-.5,s$optad[i]-.5,s$opt[i]+.5,s$optad[i]+.5,col=shade,border='white',lwd=2)
   label<-if(is.finite(gap[i])) paste0(format(signif(gap[i],3),trim=TRUE),'%') else paste0(s$valid[i],'/',s$requested[i])
   if(s$selected_for_deep[i])label<-paste0(label,' *')
   text(s$opt[i],s$optad[i],label,cex=.8,col=if(is.finite(gap[i]) && log10(1+gap[i])/hi>.55)'white' else ink)
  }
 }
 mtext(paste(title,'| Optimizer screen'),outer=TRUE,line=2,font=2,cex=1.5,col=ink)
 mtext(paste('Smoothing',format(s$smoothing[1],scientific=TRUE),'|',sum(s$completed),'/',sum(s$requested),'fits completed'),outer=TRUE,line=.5,col=ink)
 mtext('Cells: median objective above best (%) | * deep candidate (provisional while running) | gray: pending; pink: unusable',outer=TRUE,side=1,line=.4,cex=.8,col=ink)
 dev.off();if(!file.rename(tmp,dest))stop('Cannot publish optimizer graphic')
}
'''


def rank_optimizers(rows, candidates, seeds, smoothing):
    """Rank every candidate that completed all shared seeds."""
    summaries = []
    for candidate in candidates:
        tag = '-'.join(map(str,candidate))
        fits = [r for r in rows if r['candidate']==tag]
        valid = [r for r in fits if r['status']=='complete']
        values = [r['objective'] for r in valid]
        summaries.append(dict(candidate=tag, smoothing=smoothing, requested=len(seeds), completed=len(fits),
                              valid=len(valid), failed=len(fits)-len(valid),
                              usable=len(valid)==len(seeds) and {r['seed'] for r in valid}==set(seeds),
                              median=statistics.median(values) if values else None,
                              worst=max(values) if values else None, best=min(values) if values else None,
                              seconds=sum(r['seconds'] for r in fits), rank=None, selected_for_deep=False))
    ranked = sorted((r for r in summaries if r['usable']),
                    key=lambda r:(r['median'],r['worst'],r['best'],r['seconds'],r['candidate']))
    for index,row in enumerate(ranked):
        row['rank'] = index+1
    return summaries


class OptimizerScreen:
    """Module 2: full optimizer combinations at a completed CV selection."""

    def __init__(self, benchmark, selection):
        if selection['status']!='complete' or selection['provisional']:
            raise ValueError('Optimizer screening requires a complete CV selection')
        self.b = benchmark
        self.index = benchmark.a.smoothing.index(selection['smoothing'])
        self.smoothing = selection['smoothing']
        self.root = benchmark.root/'optimizer_screen'
        self.candidates = list(itertools.product(range(6),range(6),range(2),range(2)))
        # Independent of how many replacement seeds CV consumed.
        rng = random.Random(f'{benchmark.a.seed}:optimizer-screen')
        self.seeds = []
        while len(self.seeds)<benchmark.a.optimizer_seeds:
            seed = rng.randrange(1,2147483648)
            if seed not in self.seeds:
                self.seeds.append(seed)
        self.rows = []

    def reports(self):
        summary = rank_optimizers(self.rows,self.candidates,self.seeds,self.smoothing)
        selected = {r["candidate"] for r in trim_optimizers(summary,self.b.a.deep_configurations)}
        for row in summary:
            row["selected_for_deep"] = row["candidate"] in selected
        table(self.root/'summary.tsv',summary)
        try:
            self.b.checked([self.b.rscript,str(self.root/'plot.R'),str(self.root),self.b.config.stem],self.root/'plotting.log')
        except (RuntimeError,OSError) as error:
            self.b.log(f'Optimizer plot warning: {error}')
        return summary

    def update_reports(self, rows):
        self.rows = rows
        return self.reports()

    def run(self):
        b = self.b
        self.root.mkdir()
        (self.root/'plot.R').write_text(OPTIMIZER_PLOT_R)
        manifest = dict(status='running', smoothing=self.smoothing, seeds=self.seeds,
                        candidates=self.candidates, pliter=b.a.optimizer_pliter, thorough=False,
                        jobs=b.a.jobs, threads=b.a.threads, requested_fits=len(self.candidates)*len(self.seeds))
        save(self.root/'manifest.json',manifest)
        b.manifest.update(status='running', stage='optimizer_screen', cv_status='complete')
        save(b.root/'manifest.json',b.manifest)
        b.write_status('running','optimizer_screen')
        started = time.monotonic()
        total = manifest['requested_fits']
        b.log(f'Optimizer screen: {len(self.candidates)} configurations x {len(self.seeds)} shared seeds; '
              f'smooth={self.smoothing:g}, pliter={b.a.optimizer_pliter}, thorough=off')
        self.reports()
        try:
            self.rows = run_fit_stage(b,self.index,self.candidates,self.seeds,'optimizer_search',b.a.optimizer_pliter,self.root,self.update_reports)
            if any(digest(Path(p))!=h for p,h in b.hashes.items()):
                raise RuntimeError('Source input or executable changed during optimizer screening')
            summary = self.reports()
            retained = trim_optimizers(summary,b.a.deep_configurations)
            selection = dict(status='complete' if retained else 'incomplete', smoothing=self.smoothing,
                             seeds=self.seeds, pliter=b.a.optimizer_pliter, thorough=False,
                             requested_fits=total, completed_fits=len(self.rows),
                             valid_fits=sum(r['status']=='complete' for r in self.rows),
                             eligible_configurations=sum(r['usable'] for r in summary),
                             deep_candidates=retained,
                             rule='Require all shared seeds to yield valid trees; rank median, worst, best objective, then runtime and identifier. '
                                  'Select the best-ranked and lowest-individual-objective configurations, then fill in rank order up to the deep-search cap.',
                             production_config_updated=False)
            save(self.root/'selection.json',selection)
            b.consolidate(self.rows,self.root/'evaluations.jsonl')
            manifest.update(status=selection['status'],seconds=round(time.monotonic()-started,2),retained=len(retained))
            save(self.root/'manifest.json',manifest)
            b.manifest.update(status=selection['status'],stage='optimizer_screen',
                              seconds=round(time.monotonic()-b.started,2),production_unchanged=True)
            save(b.root/'manifest.json',b.manifest)
            b.log(f'Optimizer screen finished: {selection["eligible_configurations"]} eligible configurations; '
                  f'{len(selection["deep_candidates"])} selected for deep searching')
            return selection
        except BaseException as error:
            b.stop.set()
            manifest.update(status='interrupted' if isinstance(error,(KeyboardInterrupt,InterruptedError)) else 'failed',reason=str(error) or 'Interrupted')
            save(self.root/'manifest.json',manifest)
            raise


def trim_optimizers(summary, limit):
    """Keep the typical winner, individual-fit winner, then fill in rank order."""
    ranked = sorted((r for r in summary if r['usable']),key=lambda r:r['rank'])
    if not ranked:
        return []
    retained = []
    def add(row, reason):
        if len(retained)<limit and not any(r['candidate']==row['candidate'] for r in retained):
            retained.append(dict(row,selected_for=reason))
    add(ranked[0],'best median/worst ranking')
    add(min(ranked,key=lambda r:(r['best'],r['rank'])),'lowest individual objective')
    for row in ranked:
        add(row,'next-ranked configuration')
    return retained


def run_fit_stage(b, index, candidates, seeds, stage, pliter, root, report):
    """Shared scheduling/progress for the two post-CV modules."""
    rows = []
    started = time.monotonic()
    total = len(candidates)*len(seeds)
    with futures.ThreadPoolExecutor(max_workers=b.a.jobs) as pool:
        # Interleave configurations so shared seeds advance together.
        pending = {pool.submit(b.fit,index,c,seed,stage,None,pliter)
                   for seed in seeds for c in candidates}
        next_report = next_plot = time.monotonic()+30
        try:
            while pending:
                done,pending = futures.wait(pending,timeout=1,return_when=futures.FIRST_COMPLETED)
                if b.stop.is_set():
                    raise InterruptedError('Interrupted')
                for future in done:
                    rows.append(future.result())
                if done:
                    table(root/'fits.tsv',rows)
                now = time.monotonic()
                if done or now>=next_report:
                    eta = f'{(now-started)*(total-len(rows))/len(rows)/60:.0f} min' if rows else 'estimating'
                    b.log(f'{stage}: {len(rows)}/{total} complete; '
                          f'{sum(r["status"]!="complete" for r in rows)} failed; provisional ETA={eta}')
                    next_report = now+30
                if now>=next_plot:
                    report(rows)
                    next_plot = time.monotonic()+30
        except BaseException:
            b.stop.set()
            for future in pending:
                future.cancel()
            raise
    return rows


DEEP_PLOT_R = r'''
a<-commandArgs(TRUE);root<-a[1];title<-a[2]
x<-read.delim(file.path(root,'age_comparison.tsv'),check.names=FALSE)
colors<-c('#227C9D','#D59A35','#BA594A','#6B9080');cand<-unique(x$candidate)
ink<-'#243746';best<-min(x$objective)
for(ext in c('png','pdf')) {
 dest<-file.path(root,paste0('deep_search.',ext));tmp<-paste0(dest,'.tmp')
 if(ext=='png')png(tmp,width=1800,height=850,res=150) else pdf(tmp,width=12,height=5.67,useDingbats=FALSE)
 par(mfrow=c(1,2),mar=c(5,6,3,1),mgp=c(3.5,.8,0),oma=c(1,0,4,0),las=1,bty='l',col=ink,col.axis=ink,col.lab=ink)
 curves<-lapply(cand,function(c){z<-x[x$candidate==c,];z<-z[order(z$seed_index),];z$gap<-cummin(z$objective)-best;z})
 yr<-range(unlist(lapply(curves,function(z)z$gap)));if(diff(yr)==0)yr<-c(0,1e-6)
xr<-range(c(0,1,x$seed_index))
plot(NA,xlim=xr,ylim=yr,xlab='Shared seed index (0 = earlier best)',ylab='Best objective found minus current best',main='Improvement as seeds accumulate')
 for(i in seq_along(curves))lines(curves[[i]]$seed_index,curves[[i]]$gap,type='o',pch=16,cex=.45,lwd=2,col=colors[1+(i-1)%%length(colors)])
 legend('topright',cand,col=rep(colors,length.out=length(cand)),lwd=2,bty='n',cex=.8)
 plot(x$objective-best,x$max_age_difference_ma,pch=16,col=adjustcolor(colors[1+(match(x$candidate,cand)-1)%%length(colors)],.6),xlab='Objective minus current best',ylab='Largest node-age difference from best (Ma)',main='Objective and node-age agreement')
 mtext(paste(title,'| Deep seed search'),outer=TRUE,line=2,font=2,cex=1.5,col=ink)
 mtext(paste(nrow(x),'valid fits | Updated',format(Sys.time(),'%Y-%m-%d %H:%M:%S')),outer=TRUE,line=.5,col=ink)
 dev.off();if(!file.rename(tmp,dest))stop('Cannot publish deep-search graphic')
}
'''


class DeepSeedSearch:
    """Module 3: a fixed deep seed budget, without early stopping or retries."""

    def __init__(self, benchmark, screen):
        if screen['status']!='complete' or not screen['deep_candidates']:
            raise ValueError('Deep searching requires eligible optimizer configurations')
        self.b = benchmark
        self.screen = screen
        self.root = benchmark.root/'deep_seed_search'
        self.index = benchmark.a.smoothing.index(screen['smoothing'])
        self.candidates = [tuple(map(int,r['candidate'].split('-'))) for r in screen['deep_candidates']]
        rng = random.Random(f'{benchmark.a.seed}:deep-seed-search')
        self.seeds = []
        # Use fresh seeds, shared across all deep configurations.
        while len(self.seeds)<benchmark.a.deep_seeds:
            seed = rng.randrange(1,2147483648)
            if seed not in self.seeds and seed not in screen['seeds']:
                self.seeds.append(seed)
        self.rows = []
        self.records = {}
        self.baseline = None

    def load_baseline(self):
        """Carry the best validated full-tree fit at this smoothing across stages."""
        b = self.b
        best = None
        for path in (b.root/'evaluations.jsonl', b.root/'optimizer_screen/evaluations.jsonl'):
            with path.open() as handle:
                for line in handle:
                    record = json.loads(line)
                    if record['status']!='complete' or record['smoothing']!=self.screen['smoothing']:
                        continue
                    key = lambda r: (r['objective'],r['candidate'],r['seed'],r['fit_id'])
                    if best is None or key(record)<key(best):
                        best = record
        if best is None:
            raise RuntimeError('No validated screening fit available at the selected smoothing')
        (self.root/'earlier_best.tre').write_text(best['dated_tree'])
        (self.root/'earlier_best.config').write_text(best['config'])
        ages = self.root/'earlier_best_node_ages.tsv'
        b.checked([b.rscript,str(b.root/'validate.R'),str(b.root/'input.tre'),
                   str(self.root/'earlier_best.config'),str(self.root/'earlier_best.tre'),str(ages)],
                  self.root/'earlier_best_validation.log')
        with ages.open() as handle:
            best['node_ages'] = {r['node']:float(r['age_ma']) for r in csv.DictReader(handle,delimiter='\t')}
        self.records[best['fit_id']] = best
        self.baseline = {k:v for k,v in best.items() if k not in ('config','dated_tree','node_ages','validation','raw_scores','log_tail')}
        save(self.root/'earlier_best.json',best)
        b.log(f'Earlier best retained: {best["stage"]}, {best["candidate"]}, seed={best["seed"]}; objective={best["objective"]}')

    def reports(self, rows):
        self.rows = rows
        b = self.b
        valid = [r for r in rows if r['status']=='complete']
        if self.baseline is not None:
            valid = [self.baseline] + valid
        summaries = []
        for c in self.candidates:
            tag = '-'.join(map(str,c));rr = [r for r in rows if r['candidate']==tag]
            values = [r['objective'] for r in rr if r['status']=='complete']
            summaries.append(dict(candidate=tag,attempted=len(rr),requested=len(self.seeds),valid=len(values),failed=len(rr)-len(values),
                                  best=min(values) if values else None,median=statistics.median(values) if values else None,worst=max(values) if values else None))
        table(self.root/'summary.tsv',summaries)
        if not valid:
            return None
        best = min(valid,key=lambda r:(r['objective'],r['candidate'],r['seed']))
        for row in valid:
            if row['fit_id'] not in self.records:
                self.records[row['fit_id']] = json.loads((b.root/'.work'/row['fit_id']/'result.json').read_text())
        reference = self.records[best['fit_id']]['node_ages']
        comparison = []
        for row in valid:
            ages = self.records[row['fit_id']]['node_ages']
            if ages.keys()!=reference.keys():
                raise RuntimeError('Deep fits have inconsistent node mappings')
            delta = [abs(ages[n]-reference[n]) for n in reference]
            comparison.append(dict(candidate=row['candidate'],seed=row['seed'],seed_index=0 if row is self.baseline else self.seeds.index(row['seed'])+1,
                                   objective=row['objective'],objective_gap=row['objective']-best['objective'],
                                   median_age_difference_ma=statistics.median(delta),max_age_difference_ma=max(delta),
                                   nodes_over_1ma=sum(d>1 for d in delta),fit_id=row['fit_id']))
        table(self.root/'age_comparison.tsv',comparison)
        save(self.root/'best_so_far.json',best)
        try:
            b.checked([b.rscript,str(self.root/'plot.R'),str(self.root),b.config.stem],self.root/'plotting.log')
        except (RuntimeError,OSError) as error:
            b.log(f'Deep-search plot warning: {error}')
        return best

    def run(self):
        b = self.b
        self.root.mkdir()
        (self.root/'plot.R').write_text(DEEP_PLOT_R)
        manifest = dict(status='running',smoothing=self.screen['smoothing'],seeds=self.seeds,
                        candidates=self.screen['deep_candidates'],pliter=b.a.deep_pliter,thorough=False,
                        jobs=b.a.jobs,threads=b.a.threads,requested_fits=len(self.seeds)*len(self.candidates),
                        selection_rule='Lowest valid objective across earlier fits at this smoothing and deep fits; exact printed ties use candidate identifier then seed. No early stopping or seed replacement.')
        save(self.root/'manifest.json',manifest)
        b.manifest.update(status='running',stage='deep_seed_search',optimizer_screen_status='complete')
        save(b.root/'manifest.json',b.manifest)
        b.write_status('running','deep_seed_search')
        started = time.monotonic()
        b.log(f'Deep seed search: {len(self.candidates)} configurations x {len(self.seeds)} shared seeds; '
              f'smooth={self.screen["smoothing"]:g}, pliter={b.a.deep_pliter}, thorough=off')
        try:
            self.load_baseline()
            self.reports([])
            self.rows = run_fit_stage(b,self.index,self.candidates,self.seeds,'deep_seed_search',b.a.deep_pliter,self.root,self.reports)
            if any(digest(Path(p))!=h for p,h in b.hashes.items()):
                raise RuntimeError('Source input or executable changed during deep searching')
            best = self.reports(self.rows)
            selection = dict(status='complete' if best else 'incomplete',smoothing=self.screen['smoothing'],best_fit=best,
                             attempted_fits=len(self.rows),valid_fits=sum(r['status']=='complete' for r in self.rows),
                             winning_fit_stage=best['stage'] if best else None,
                             production_config_updated=False,standalone_validation_pending=True)
            if best:
                record = self.records[best['fit_id']]
                (self.root/'best.tre').write_text(record['dated_tree'])
                best_config = config_text(record['config'],dict(treefile='../input.tre',outfile='best_standalone.tre'),{})
                (self.root/'best.config').write_text(best_config)
                table(self.root/'best_node_ages.tsv',[dict(node=n,age_ma=v) for n,v in record['node_ages'].items()])
                save(self.root/'best.json',record)
            save(self.root/'selection.json',selection)
            b.consolidate(self.rows,self.root/'evaluations.jsonl')
            manifest.update(status=selection['status'],seconds=round(time.monotonic()-started,2),valid_fits=selection['valid_fits'])
            save(self.root/'manifest.json',manifest)
            b.manifest.update(status=selection['status'],stage='deep_seed_search',seconds=round(time.monotonic()-b.started,2),production_unchanged=True)
            save(b.root/'manifest.json',b.manifest)
            b.log(f'Deep search finished: {selection["valid_fits"]}/{len(self.rows)} valid fits; '
                  f'best objective={best["objective"] if best else None} from {best["stage"] if best else None}; standalone confirmation and publication remain pending')
            return selection
        except BaseException as error:
            b.stop.set()
            manifest.update(status='interrupted' if isinstance(error,(KeyboardInterrupt,InterruptedError)) else 'failed',reason=str(error) or 'Interrupted')
            save(self.root/'manifest.json',manifest)
            raise


def publish_files(files, backup_dir):
    """Replace the small publication set; roll it back if a write is interrupted."""
    backup_dir.mkdir()
    previous = {}
    for path in files:
        if path.is_symlink():
            raise ValueError(f'Refusing to replace a symlinked publication file: {path}')
        previous[path] = path.read_text() if path.exists() else None
        if previous[path] is not None:
            (backup_dir/path.name).write_text(previous[path])
    replaced = []
    try:
        for path,text in files.items():
            path.parent.mkdir(parents=True,exist_ok=True)
            replaced.append(path)
            atomic(path,text)
    except BaseException:
        for path in reversed(replaced):
            try:
                if previous[path] is None:
                    path.unlink(missing_ok=True)
                else:
                    atomic(path,previous[path])
            except BaseException as rollback_error:
                # Keep restoring the other files and preserve the original failure.
                print(f'Rollback failed for {path}: {rollback_error}; backup: {backup_dir}',file=sys.stderr)
        raise


class FinalPublication:
    """Confirm once, publish the better validated fit, and render existing plots."""

    def __init__(self, benchmark, deep):
        if deep['status']!='complete' or not deep['best_fit']:
            raise ValueError('Final publication requires a valid deep-search winner')
        self.b = benchmark
        self.deep = deep
        self.root = benchmark.root/'final'
        self.generated = benchmark.config.parent/'generated'
        self.output = self.generated/(benchmark.config.stem+'.treePL.tre')
        self.calibrations = self.generated/(benchmark.config.stem+'.calibrations.csv')
        self.published = False

    def status(self, status, stage):
        b = self.b
        self.manifest.update(status=status,stage=stage,published=self.published)
        save(self.root/'manifest.json',self.manifest)
        b.manifest.update(status=status,stage=stage,published=self.published,production_unchanged=not self.published)
        save(b.root/'manifest.json',b.manifest)
        b.write_status(status,stage,self.published)

    def plot(self):
        b = self.b
        self.status('published','tree_plotting')
        b.checked([b.rscript,str(b.topology_plot)],self.generated/'tree_plotting.log',cwd=b.config.parent)
        scientific = self.generated/(b.config.stem+'.scientific.treePL.tre')
        self.status('published','dated_plotting')
        title = {'astralpro.l6p1':'ASTRAL-Pro l6p1','roadies_v1.1.16b':'ROADIES v1.1.16b'}.get(b.config.stem,b.config.stem)
        dated = self.generated/(b.config.stem+'.dated.pdf')
        b.checked([b.rscript,str(b.dated_plot),'--tree',str(scientific),'--accession-tree',str(self.output),
                   '--calibrations',str(self.calibrations),'--output',str(dated),'--title',title],
                  self.generated/'dated_plotting.log',cwd=b.config.parent)
        outputs = [scientific,dated,self.generated/(b.config.stem+'.treePL.png'),
                   self.generated/(b.config.stem+'.calibrated_node_ages.tsv')]
        if any(not p.is_file() or p.stat().st_size==0 for p in outputs):
            raise RuntimeError('Plotting returned without all expected tree/graphic/age-table outputs')
        return {str(p):digest(p) for p in outputs}

    def run(self):
        b = self.b
        self.root.mkdir()
        self.manifest = dict(status='running',published=False)
        self.status('running','final_confirmation')
        try:
            original = json.loads((b.root/'deep_seed_search/best.json').read_text())
            candidate = tuple(map(int,original['candidate'].split('-')))
            index = b.a.smoothing.index(original['smoothing'])
            b.log('Final confirmation: repeating the winning smoothing, optimizers, seed, iteration budget, and thread count; thorough off')
            if original['threads']!=b.a.threads or original['thorough']:
                raise ValueError('Winning thread/thorough settings do not match confirmation controls')
            repeat = b.fit(index,candidate,original['seed'],'final_confirmation',None,original['pliter'])
            repeat_record = json.loads((b.root/'.work'/repeat['fit_id']/'result.json').read_text())
            comparison = dict(original_objective=original['objective'],confirmation_status=repeat['status'],
                              confirmation_objective=repeat['objective'],objective_change=None,
                              median_age_difference_ma=None,max_age_difference_ma=None,
                              selected_source=original['stage'],same_printed_objective=False)
            selected = original
            if repeat['status']=='complete':
                if original['node_ages'].keys()!=repeat_record['node_ages'].keys():
                    raise RuntimeError('Confirmation node mappings differ')
                delta = [abs(v-repeat_record['node_ages'][n]) for n,v in original['node_ages'].items()]
                comparison.update(objective_change=repeat['objective']-original['objective'],
                                  median_age_difference_ma=statistics.median(delta),max_age_difference_ma=max(delta),
                                  same_printed_objective=repeat['objective']==original['objective'])
                if repeat['objective']<original['objective']:
                    selected = repeat_record
                    comparison['selected_source'] = 'final_confirmation'
            save(self.root/'confirmation.json',comparison)
            b.log(f'Confirmation: {repeat["status"]}; original={original["objective"]}, repeat={repeat["objective"]}; '
                  f'keeping {comparison["selected_source"]}')
            self.status('running','final_validation')
            selected_tree = self.root/'selected.tre'
            selected_tree.write_text(selected['dated_tree'])
            c = tuple(map(int,selected['candidate'].split('-')))
            updates = dict(treefile=b.options['treefile'],outfile='generated/'+self.output.name,
                           smooth=smoothing_text(selected['smoothing']),seed=selected['seed'],pliter=selected['pliter'],
                           nthreads=selected['threads'],opt=c[0],optad=c[1],cviter=b.a.cviter)
            final_config = config_text(b.original,updates,dict(moredetail=bool(c[2]),moredetailad=bool(c[3]),thorough=False))
            calibration_check(final_config,b.master,b.config.stem)
            (self.root/'published.config').write_text(final_config)
            b.checked([b.rscript,str(b.root/'validate.R'),str(b.root/'input.tre'),str(self.root/'published.config'),
                       str(selected_tree),str(self.root/'selected_node_ages.tsv')],self.root/'selected_validation.log')
            with (b.root/'master_calibrations.csv').open() as handle:
                reader = csv.DictReader(handle)
                fields = reader.fieldnames
                subset = [r for r in reader if r['node_'+b.config.stem.replace('.','_')].strip()]
            out = io.StringIO();writer = csv.DictWriter(out,fieldnames=fields)
            writer.writeheader();writer.writerows(subset)
            if any(digest(Path(p))!=h for p,h in b.hashes.items()):
                raise RuntimeError('Source input or executable changed before publication')
            # Save confirmation records before removing their working files.
            b.consolidate([repeat],self.root/'evaluations.jsonl')
            save(self.root/'selection.json',dict(source=comparison['selected_source'],candidate=selected['candidate'],
                                               smoothing=selected['smoothing'],seed=selected['seed'],pliter=selected['pliter'],
                                               threads=selected['threads'],thorough=False,objective=selected['objective'],
                                               winning_fit_stage=selected['stage'],
                                               confirmation_valid=repeat['status']=='complete',tree_sha256=digest(selected_tree)))
            self.status('running','publication')
            publish_files({self.output:selected['dated_tree'],self.calibrations:out.getvalue(),b.config:final_config},
                          self.root/'before_publication')
            self.published = True
            self.manifest.update(selected_source=comparison['selected_source'],objective=selected['objective'],
                                 confirmation_valid=repeat['status']=='complete',
                                 published_hashes={str(p):digest(p) for p in (self.output,self.calibrations,b.config)})
            self.status('published','publication')
            self.manifest['plot_hashes'] = self.plot()
            b.manifest.update(seconds=round(time.monotonic()-b.started,2),final_selection=str(self.root/'selection.json'))
            self.status('complete','complete')
            b.log(f'COMPLETE: selected tree, optimized config, scientific-name tree, PNG, calibration ages, and dated-tree PDF published in {self.generated}')
            return dict(status='complete',published=True)
        except BaseException as error:
            self.manifest['reason'] = str(error) or 'Interrupted'
            state = 'published_plot_failed' if self.published else 'failed'
            if isinstance(error,(KeyboardInterrupt,InterruptedError)):
                state = 'published_interrupted' if self.published else 'interrupted'
            self.status(state,self.manifest.get('stage','final_confirmation'))
            raise


def main():
    args = parse_args()
    benchmark = RandomCV(args)
    def stop(signum, frame):
        benchmark.stop.set()
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM,stop)
    signal.signal(signal.SIGINT,stop)
    if args.dry_run:
        benchmark.preflight()
        return 0
    with (benchmark.config.parent/'.treepl.lock').open('a') as lock:
        try:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another run for this topology is active; no outputs changed')
        benchmark.preflight()
        try:
            benchmark.prepare()
            selection = benchmark.run()
            if selection['status']=='complete':
                selection = OptimizerScreen(benchmark,selection).run()
            if selection['status']=='complete':
                selection = DeepSeedSearch(benchmark,selection).run()
            if selection['status']=='complete':
                selection = FinalPublication(benchmark,selection).run()
        except BaseException as error:
            benchmark.stop.set()
            if hasattr(benchmark,'manifest'):
                state = ('published_interrupted' if isinstance(error,(KeyboardInterrupt,InterruptedError)) else 'published_plot_failed') if benchmark.manifest.get('published') else ('interrupted' if isinstance(error,(KeyboardInterrupt,InterruptedError)) else 'failed')
                benchmark.manifest.update(status=state, reason=str(error) or 'Interrupted')
                save(benchmark.root/'manifest.json',benchmark.manifest)
                benchmark.write_status(state,benchmark.manifest.get('stage','preparation'),benchmark.manifest.get('published',False))
            raise
        if selection['status']!='complete':
            benchmark.write_status('incomplete',benchmark.manifest.get('stage','cv'))
        return 0 if selection['status']=='complete' else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (ValueError,RuntimeError,OSError,KeyError) as error:
        sys.exit(f'Error: {error}')
    except KeyboardInterrupt:
        sys.exit(130)
