
suppressPackageStartupMessages(library(ape))
a <- commandArgs(TRUE)
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
if(h<=0 || diff(range(d[seq_len(Ntip(t))]))>0.001) stop('Non-ultrametric dated tree.')
for(p in pairs) {
  node <- getMRCA(t,p[3:4])
  for(k in c('min','max')) {
    v <- Filter(function(x) length(x)>1 && x[1]==k && x[2]==p[2],entries)
    b <- as.numeric(v[[1]][3])
    if((k=='min' && ages[node]<b-0.001) || (k=='max' && ages[node]>b+0.001)) stop('Calibration violation.')
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
