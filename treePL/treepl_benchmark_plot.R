#!/usr/bin/env Rscript
# Offline benchmark graphics. All transformations and exclusions are labelled.
a <- commandArgs(TRUE)
if(length(a)!=1) stop('Usage: treepl_benchmark_plot.R RUN_DIRECTORY')
root <- normalizePath(a[1],mustWork=TRUE)
read <- function(name) {
 p<-file.path(root,name)
 if(file.exists(p)) {
  x<-read.delim(p,stringsAsFactors=FALSE,check.names=FALSE)
  if(!'fit_id' %in% names(x) && 'directory' %in% names(x)) x$fit_id<-x$directory
  x
 } else NULL
}
fits<-read('fits.tsv');opt<-read('optimizer_summary.tsv');cv<-read('cv_scores.tsv');cs<-read('cv_summary.tsv');fin<-read('final_summary.tsv')
if(is.null(fits)) quit()
run_name<-basename(dirname(dirname(root)))
ink<-'#243746';muted<-'#627584';grid<-'#E7EDF1';gold<-'#D59A35'
basecolors<-c('#227C9D','#D56B36','#679436','#8B5AA5','#B58B16','#007F73','#CC6677','#4477AA','#774422')
seeds<-sort(unique(fits$seed));colors<-setNames(rep(basecolors,length.out=length(seeds)),as.character(seeds))
truth<-function(x) tolower(as.character(x)) %in% c('true','1')
style<-function(...) par(family='sans',col=ink,col.axis=ink,col.lab=ink,col.main=ink,fg=ink,las=1,mgp=c(2.8,.7,0),...)
heading<-function(title,subtitle) {
 mtext(paste(run_name,'|',title),side=3,outer=TRUE,line=2,font=2,cex=1.3,adj=.015,col=ink)
 mtext(subtitle,side=3,outer=TRUE,line=.55,cex=.8,adj=.015,col=muted)
}
export<-function(name,draw,width=12,height=8) {
 for(ext in c('png','pdf')) {
  path<-file.path(root,paste0(name,'.',ext));tmp<-paste0(path,'.tmp')
  if(ext=='png') png(tmp,width=width,height=height,units='in',res=170) else pdf(tmp,width=width,height=height,useDingbats=FALSE)
  tryCatch(draw(),finally=dev.off())
  if(!file.rename(tmp,path)) stop('Cannot publish ',path)
 }
}
empty<-function(message) {plot.new();text(.5,.5,message,col=muted)}

if(!is.null(opt)) {
 opt$usable<-truth(opt$usable);opt$selected<-truth(opt$selected)
 values<-sort(unique(opt$smoothing),decreasing=TRUE);candidates<-sort(unique(opt$candidate))
 opt$gap<-NA_real_
 for(s in values) {
  good<-opt$smoothing==s & opt$usable
  if(any(good)) {best<-min(opt$best[good]);opt$gap[good]<-pmax(0,100*(opt$median[good]-best)/max(abs(best),1e-12))}
 }
 draw_optimizer<-function() {
  layout(matrix(1:2,ncol=1),heights=c(max(4,length(candidates)*.15),3.2))
  style(oma=c(2,0,4.5,0),mar=c(3.4,7,1.2,2))
  palette<-colorRampPalette(c('#F2F7FA','#80B8C8','#227C9D','#B76453','#862F3D'))(256)
  plot(NA,xlim=c(.5,length(values)+.5),ylim=c(.5,length(candidates)+.5),xaxt='n',yaxt='n',xlab='',ylab='',bty='n',xaxs='i',yaxs='i')
  axis(1,at=seq_along(values),labels=format(values,scientific=TRUE,trim=TRUE),cex.axis=.8)
  axis(2,at=seq_along(candidates),labels=rev(candidates),tick=FALSE,cex.axis=.65)
  for(xx in seq_along(values)) for(yy in seq_along(candidates))
   rect(xx-.48,yy-.48,xx+.48,yy+.48,col='#FFF4DF',border='white',lwd=.3)
  for(k in seq_len(nrow(opt))) {
   xx<-match(opt$smoothing[k],values); yy<-length(candidates)+1-match(opt$candidate[k],candidates)
   z<-opt$gap[k];fill<-if(is.finite(z)) palette[1+floor(255*min(3,log10(1+z))/3)] else '#DDE2E6'
   rect(xx-.48,yy-.48,xx+.48,yy+.48,col=fill,border='white',lwd=.3)
   if(opt$selected[k]) rect(xx-.45,yy-.45,xx+.45,yy+.45,border=gold,lwd=2)
  }
  mtext('opt-optad-detail-detailad',side=2,line=5.9,las=0,cex=.85)
  legend('top',inset=c(0,-.06),xpd=NA,legend=c('0%','1%','10%','100%','999%+','Unusable','Not shortlisted','Selected'),fill=c(palette[1+floor(255*log10(1+c(0,1,10,100,999))/3)],'#DDE2E6','#FFF4DF',NA),border=c(rep(NA,7),gold),horiz=TRUE,bty='n',cex=.68)
  par(mar=c(4,5,2.5,2))
  z<-fits[fits$stage=='screen' & fits$status=='complete',]
  selected<-opt[opt$selected,]
  z<-z[paste(z$smooth,z$candidate) %in% paste(selected$smoothing,selected$candidate),]
  assessments<-read('assessments.tsv')
  gooddirs<-assessments$fit_id[assessments$assessment=='retained']
  z<-z[z$fit_id %in% gooddirs,]
  if(nrow(z)) {
   z$gap<-vapply(seq_len(nrow(z)),function(i) {best<-min(opt$best[opt$smoothing==z$smooth[i] & opt$usable]);max(0,100*(z$objective[i]-best)/max(abs(best),1e-12))},numeric(1))
   y<-log10(1+z$gap);ylim<-c(0,max(.01,y)*1.1)
   plot(NA,xlim=c(.5,length(values)+.5),ylim=ylim,xaxt='n',xlab='Smoothing',ylab='log10(1 + objective gap %)',bty='l')
   abline(h=axTicks(2),col=grid);axis(1,at=seq_along(values),labels=format(values,scientific=TRUE,trim=TRUE),cex.axis=.8)
   for(j in seq_along(seeds)) {q<-z[z$seed==seeds[j],];points(match(q$smooth,values)+(j-(length(seeds)+1)/2)*.035,log10(1+q$gap),col=colors[j],pch=15+(j-1)%%4,cex=.8)}
   title('Selected configurations: retained individual seeds',adj=0,cex.main=.95)
  } else empty('No usable optimizer configuration')
  heading('Optimizer landscape',paste(length(candidates),'configurations |',length(values),'smoothing values |',length(seeds),'shared seeds |',sum(opt$outliers),'outliers excluded'))
  mtext('Cells show median objective gap above the best retained fit at the same smoothing. Gray: unusable. Cream: not shortlisted for confirmation.',side=1,outer=TRUE,line=.3,cex=.75,col=muted)
 }
 export('optimizer_landscape',draw_optimizer,height=max(9,6+length(candidates)*.15))
}

if(!is.null(cv) && !is.null(cs)) {
 cs$usable<-truth(cs$usable);cs$selected<-truth(cs$selected)
 draw_cv<-function(filtered) {
  style(mfrow=c(1,2),oma=c(5.6,0,4.5,0),mar=c(4.4,5,2.5,1.5))
  finite<-is.finite(cv$score) & cv$score>=0
  kept<-finite & cv$assessment=='retained'
  use<-if(filtered) kept else finite
  values<-sort(unique(cs$smoothing),decreasing=TRUE)
  winner<-cs$smoothing[cs$selected]
  for(zoom in c(FALSE,TRUE)) {
   idx<-seq_along(values)
   if(zoom && length(winner)) {k<-match(winner,values);idx<-seq(max(1,k-2),min(length(values),k+2))}
   ss<-values[idx];q<-cv[use & cv$smoothing %in% ss,]
   if(!nrow(q)) {empty('No usable CV scores');next}
   # Log transform for the raw view keeps recorded extremes visible; filtered view stays linear.
   transform<-if(filtered) function(x) x/1e6 else function(x) log10(1+x)
   yy<-transform(q$score);yr<-range(yy);pad<-max(diff(yr)*.08,abs(mean(yr))*.01,1e-8);yr<-yr+c(-pad,pad)
   plot(NA,xlim=rev(range(log10(ss)))+c(.15,-.15),ylim=yr,xaxt='n',xlab='Smoothing (log scale)',ylab=if(filtered) 'CV score (millions)' else 'log10(1 + CV score)',bty='l')
   abline(h=axTicks(2),col=grid);axis(1,at=log10(ss),labels=format(ss,scientific=TRUE,trim=TRUE),cex.axis=.8)
   for(j in seq_along(seeds)) {
    z<-cv[cv$seed==seeds[j],]; z$xx<-log10(z$smoothing);z<-z[order(z$xx),]
    ok<-is.finite(z$score) & z$score>=0 & (!filtered | z$assessment=='retained');yy<-transform(z$score);yy[!ok]<-NA
    lines(z$xx,yy,col=colors[j],lwd=1.5,lty=1+(j-1)%%6);points(z$xx,yy,col=colors[j],pch=15+(j-1)%%4,cex=.7)
   }
   med<-cs$median;med[!cs$usable]<-NA
   lines(log10(cs$smoothing),transform(med),col=ink,lwd=2.5,lty=2)
   if(length(winner)) abline(v=log10(winner),col=gold,lty=3,lwd=1.5)
   title(if(zoom) 'Around the selected minimum' else 'All requested values',adj=0,cex.main=.95)
  }
  heading(if(filtered) 'CV variation | usable replicates' else 'CV variation | all finite scores',paste(length(seeds),'shared seeds |',sum(cv$assessment=='outlier'),'outliers |',sum(cv$status=='failed'),'failed fits'))
  par(fig=c(0,1,0,1),mar=rep(0,4),oma=rep(0,4),new=TRUE);plot.new()
  legend('bottom',inset=c(0,.09),legend=c(paste('Seed',seeds),'Usable median'),col=c(colors,ink),lty=c(1+(seq_along(seeds)-1)%%6,2),lwd=c(rep(1.5,length(seeds)),2.5),ncol=min(5,length(seeds)+1),bty='n',cex=.73)
  text(.5,.025,if(filtered) 'Failed fits and flagged gross outliers excluded; raw results are preserved. Gold line: selected smoothing.' else 'Gross outliers are shown on a logarithmic score axis. Dashed median uses only usable replicates.',cex=.8,col=muted)
 }
 export('cv_variation',function() draw_cv(FALSE))
 export('cv_variation_filtered',function() draw_cv(TRUE))
}

if(!is.null(fin)) {
 draw_final<-function() {
  style(mfrow=c(1,2),oma=c(3.2,0,4.5,0),mar=c(6,5,3.5,1.4))
  good<-fin$status=='complete' & is.finite(fin$objective)
  if(any(good)) {
   best<-min(fin$objective[good]);gap<-100*(fin$objective-best)/max(abs(best),1e-12)
   xx<-seq_len(nrow(fin));plot(xx[good],gap[good],xlim=c(.7,nrow(fin)+.3),ylim=c(0,max(.001,gap[good])*1.1),xaxt='n',pch=19,cex=1.5,col=ifelse(fin$stage[good]=='screen','#227C9D',ifelse(truth(fin$thorough[good]),gold,'#679436')),xlab='',ylab='Objective above best (%)',bty='l')
   axis(1,at=xx,labels=paste(fin$stage,paste0('seed ',fin$seed),paste0('p=',fin$pliter,ifelse(truth(fin$thorough),' T','')),sep='\n'),cex.axis=.55)
   abline(h=0,col=grid);title('Final fit comparison',adj=0,cex.main=1)
  } else empty('No valid final fits')
  d<-read('final_iteration_check_ages.tsv')
  if(!is.null(d)) {
   plot(d$before_ma,d$after_ma,pch=16,cex=.5,col=adjustcolor('#227C9D',.5),xlab='Screening node age (Ma)',ylab='Higher-budget node age (Ma)',bty='l');abline(0,1,col=gold,lwd=1.5,lty=2)
   title('Node-age agreement',adj=0,cex.main=1,line=1.8)
   mtext(sprintf('Median |change| %.4g Ma; maximum %.4g Ma',median(abs(d$delta_ma)),max(abs(d$delta_ma))),side=3,line=.2,cex=.78,col=muted)
  } else empty('Higher-budget age comparison unavailable')
  heading('Final validation','All shared seeds | green: without thorough; gold: thorough | selection in final_summary.tsv')
  mtext('Objective and age differences are diagnostics, not automatic convergence claims.',side=1,outer=TRUE,line=1,cex=.8,col=muted)
 }
 export('final_diagnostics',draw_final,width=max(12,7+nrow(fin)*.6),height=7)
}
