
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
