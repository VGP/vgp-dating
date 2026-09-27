
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
