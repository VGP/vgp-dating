
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
