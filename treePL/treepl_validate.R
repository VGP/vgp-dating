#!/usr/bin/env Rscript
# Validate an input or dated tree; report ages by the authoritative input's nodes.
suppressPackageStartupMessages(library(ape))
a <- commandArgs(TRUE)
if(length(a)!=4) stop('Usage: treepl_validate.R INPUT CONFIG DATED_OR_DASH AGE_TSV')
ref <- read.tree(a[1])
check_tree <- function(t) {
    if(!inherits(t,'phylo') || !is.rooted(t) || anyDuplicated(t$tip.label) ||
       is.null(t$edge.length) || any(!is.finite(t$edge.length)) || any(t$edge.length<0))
        stop('Expected one rooted tree with unique tips and finite nonnegative lengths.')
}
check_tree(ref)
lines <- trimws(sub('#.*$','',readLines(a[2])))
entries <- lapply(lines[grepl('^(mrca|min|max)\\s*=',lines)], function(x)
    strsplit(gsub('=',' ',x,fixed=TRUE),'[[:space:]]+')[[1]])
pairs <- Filter(function(x) x[1]=='mrca',entries)
if(!length(pairs)) stop('No calibrations.')
for(p in pairs) if(length(p)!=4 || !all(p[3:4] %in% ref$tip.label)) stop('Missing calibration taxa.')
if(a[3]=='-') { cat('Input valid:',Ntip(ref),'tips;',length(pairs),'calibrations\n'); quit() }
t <- read.tree(a[3]); check_tree(t)
if(!isTRUE(all.equal.phylo(ref,t,use.edge.length=FALSE,use.tip.label=TRUE))) stop('Dated topology or taxa differ.')
d <- node.depth.edgelength(t); h <- max(d[seq_len(Ntip(t))])
if(h<=0 || diff(range(d[seq_len(Ntip(t))]))>0.001) stop('Tree is not ultrametric within 0.001 Ma.')
ages <- h-d
for(p in pairs) {
    node <- getMRCA(t,p[3:4])
    for(key in c('min','max')) {
        b <- Filter(function(x) x[1]==key && x[2]==p[2],entries)
        if(length(b)!=1 || length(b[[1]])!=3) stop('Missing/duplicate bound: ',p[2])
        bound <- as.numeric(b[[1]][3])
        if(!is.finite(bound) || (key=='min' && ages[node]<bound-0.001) ||
           (key=='max' && ages[node]>bound+0.001)) stop('Calibration violation: ',p[2])
    }
}
keys <- function(t) {
    ch <- split(t$edge[,2],t$edge[,1]); memo<-vector('list',Ntip(t)+t$Nnode)
    descend <- function(n) {
        if(length(memo[[n]])) return(memo[[n]])
        memo[[n]] <<- if(n<=Ntip(t)) t$tip.label[n] else sort(unlist(lapply(ch[[as.character(n)]],descend)))
        memo[[n]]
    }
    vapply(seq.int(Ntip(t)+1,Ntip(t)+t$Nnode),function(n) paste(descend(n),collapse='|'),character(1))
}
idx <- match(keys(ref),keys(t)); if(anyNA(idx)) stop('Clades differ.')
write.table(data.frame(node=seq.int(Ntip(ref)+1,Ntip(ref)+ref$Nnode),
    age_ma=ages[Ntip(t)+idx]),a[4],sep='\t',quote=FALSE,row.names=FALSE)
cat('Dated tree valid: topology, ages, ultrametricity, and all calibration bounds.\n')
