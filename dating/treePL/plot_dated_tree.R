#!/usr/bin/env Rscript
# One-page dated-tree atlas. Requires only ape; all rendering is offline.
suppressPackageStartupMessages(library(ape))
args <- commandArgs(trailingOnly = TRUE)
usage <- paste('Usage: Rscript dating/treePL/plot_dated_tree.R --tree TREE --output PDF',
               '[--accession-tree TREE] [--calibrations CSV] [--annotations TSV]',
               '[--title TEXT] [--width INCHES] [--height INCHES]', sep = '\n  ')
if (!length(args) || '--help' %in% args) { cat(usage, '\n'); quit(status = 0) }
opts <- list()
for (i in seq(1, length(args), by = 2)) {
    if (i == length(args) || !args[i] %in% c('--tree','--output','--accession-tree',
        '--calibrations','--annotations','--title','--width','--height')) stop(usage)
    opts[[substring(args[i], 3)]] <- args[i+1]
}
if (is.null(opts$tree) || is.null(opts$output)) stop(usage)
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
repo <- dirname(dirname(dirname(normalizePath(script))))
annotation_file <- if (is.null(opts$annotations)) file.path(repo,'trees/annotations.tsv') else opts$annotations
ann <- read.delim(annotation_file, comment.char = '', stringsAsFactors = FALSE)
names(ann)[1] <- 'accession'
if (anyDuplicated(ann$accession)) stop('Annotation accessions must be unique.')
annotation_rows <- function(labels) {
    result <- match(labels,ann$accession)
    if ('AssemblyId' %in% names(ann)) for(i in which(is.na(result))) {
        candidate <- which(!is.na(ann$AssemblyId) & ann$AssemblyId == labels[i])
        if(length(candidate)==1L) {
            result[i] <- candidate
            message('Annotation alias: ',labels[i],' -> ',ann$accession[candidate],
                    ' (label only; calibration tip identity unchanged).')
        }
    }
    result
}

tr <- read.tree(opts$tree)
if (!inherits(tr,'phylo') || !is.rooted(tr) || is.null(tr$edge.length) ||
    any(!is.finite(tr$edge.length)) || any(tr$edge.length < 0) ||
    anyDuplicated(tr$tip.label)) {
    stop('Input must be a rooted, ultrametric tree with unique tips and finite nonnegative branch lengths (Ma).')
}
n <- Ntip(tr); nodes <- seq.int(n+1L,n+tr$Nnode)
age_tolerance <- 0.001
depths <- node.depth.edgelength(tr)
if(diff(range(depths[seq_len(n)]))>age_tolerance) stop('Tip ages differ by more than the pipeline tolerance of 0.001 Ma.')
ages <- max(depths[seq_len(n)]) - depths
ages[seq_len(n)] <- 0
height <- max(ages)
if (height <= 0) stop('Tree has no positive time span.')
# Preserve explicit integer node IDs, otherwise use ape indices from the input.
ids <- tr$node.label
if (length(ids) != tr$Nnode || anyNA(ids) || any(!grepl('^[0-9]+$',ids)) || anyDuplicated(ids)) ids <- as.character(nodes)
node_id <- rep(NA_character_,length(ages)); node_id[nodes] <- ids

# A companion supplies exact accession identities for a scientific-name tree.
accessions <- tr$tip.label
if (!is.null(opts[['accession-tree']])) {
    companion <- read.tree(opts[['accession-tree']])
    if (Ntip(companion) != n || anyDuplicated(companion$tip.label)) stop('Companion tip count/identifiers differ.')
    ai <- annotation_rows(companion$tip.label)
    if (anyNA(ai)) stop('Companion has accessions absent from annotations; resolve aliases explicitly first.')
    sci <- gsub(' ','_',ann$ScientificName[ai])
    duplicate <- duplicated(sci) | duplicated(sci,fromLast=TRUE)
    sci[duplicate] <- paste(sci[duplicate],companion$tip.label[duplicate],sep='_')
    display <- if (setequal(tr$tip.label,companion$tip.label)) companion$tip.label else sci
    if (anyDuplicated(display) || !setequal(display,tr$tip.label)) stop('Scientific/accession tip correspondence is ambiguous or incomplete.')
    accessions <- companion$tip.label[match(tr$tip.label,display)]
    check <- tr; check$tip.label <- accessions
    if (!isTRUE(all.equal.phylo(check,companion,use.edge.length=TRUE,use.tip.label=TRUE,tolerance=1e-7))) {
        stop('Scientific and accession trees differ in topology or branch lengths.')
    }
} else if (any(!accessions %in% ann$accession)) {
    # Unique scientific names can be used for coloring, but never guessed for calibration identity.
    if (!is.null(opts$calibrations)) stop('Supply --accession-tree to map calibrations on a scientific-name tree.')
}
ann_index <- annotation_rows(accessions)
if (is.null(opts$calibrations)) {
    missing <- is.na(ann_index)
    names_unique <- gsub(' ','_',ann$ScientificName)
    ambiguous <- duplicated(names_unique) | duplicated(names_unique,fromLast=TRUE)
    names_unique[ambiguous] <- NA_character_
    ann_index[missing] <- match(tr$tip.label[missing],names_unique)
}
# Color only pure descendant groups; mixed ancestral branches remain charcoal.
palette <- c(Amphibians='#4E79A7',Birds='#59A14F',Crocs='#E15759',Fishes='#F28E2B',
             Mammals='#B07AA1',Sharks='#76B7B2',Squamates='#EDC948',Turtles='#9C755F',Other='#424B54')
group <- rep('Other',n+tr$Nnode)
lineage <- tolower(ann$VGPLineage[ann_index]); super <- ann$Superorder[ann_index]
for (g in c('Amphibians','Birds','Mammals','Sharks')) group[which(lineage==tolower(g))] <- g
# VGPLineage separates primates; the broader Lineage identifies all mammals.
if ('Lineage' %in% names(ann)) {
    group[which(tolower(trimws(ann$Lineage[ann_index])) == 'mammals')] <- 'Mammals'
}
for (pattern in c('Actinopterygii','Testudines','Crocodylia','Squamata')) {
    g <- c(Actinopterygii='Fishes',Testudines='Turtles',Crocodylia='Crocs',Squamata='Squamates')[[pattern]]
    group[which(grepl(pattern,super,fixed=TRUE))] <- g
}
children <- split(tr$edge[,2],tr$edge[,1])
descendants <- function(node) {
    if (node<=n) return(node)
    unlist(lapply(children[[as.character(node)]],descendants),use.names=FALSE)
}
for (node in nodes) {
    gs <- unique(group[descendants(node)])
    if (length(gs)==1) group[node] <- gs
}
cal <- data.frame()
if (!is.null(opts$calibrations)) {
    cal <- read.csv(opts$calibrations,stringsAsFactors=FALSE,check.names=FALSE)
    required <- c('calibration_id','node_name','min_ma','max_ma','taxon1_accession','taxon2_accession')
    if (!all(required %in% names(cal))) stop('Calibration CSV lacks required master columns.')
    if (anyDuplicated(cal$calibration_id) || any(!is.finite(cal$min_ma)) || any(!is.finite(cal$max_ma)) || any(cal$min_ma>cal$max_ma)) stop('Invalid calibration IDs or ranges.')
    bad <- !cal$taxon1_accession %in% accessions | !cal$taxon2_accession %in% accessions
    if (any(bad)) stop('Missing defining accessions for: ',paste(cal$calibration_id[bad],collapse=', '),'. Resolve these before plotting constraints.')
    mapping <- tr; mapping$tip.label <- accessions
    cal$ape_node <- vapply(seq_len(nrow(cal)),function(i) getMRCA(mapping,c(cal$taxon1_accession[i],cal$taxon2_accession[i])),integer(1))
    cal$node_id <- node_id[cal$ape_node]; cal$estimated_age_ma <- ages[cal$ape_node]
    cal$group <- group[cal$ape_node]
    cal$position <- ifelse(cal$max_ma>cal$min_ma,(cal$estimated_age_ma-cal$min_ma)/(cal$max_ma-cal$min_ma),NA_real_)
    cal$status <- ifelse(cal$estimated_age_ma < cal$min_ma-age_tolerance | cal$estimated_age_ma > cal$max_ma+age_tolerance,'outside','within')
    if (any(cal$status=='outside')) warning('Ages outside constraints: ',paste(cal$calibration_id[cal$status=='outside'],collapse=', '))
}
# ICS 2024/12 boundaries (Ma); CGMW colors from official ICS chart data.
# https://stratigraphy.org/ICSchart/ChronostratChart2024-12.pdf
# https://github.com/i-c-stratigraphy/chart/blob/main/chart.ttl (colors, retrieved 2026-09-20)
geology <- data.frame(name=c('Quaternary','Neogene','Paleogene','Cretaceous','Jurassic','Triassic','Permian','Carboniferous','Devonian','Silurian','Ordovician','Cambrian','Ediacaran','Cryogenian','Tonian'),
 short=c('Q','N','Pg','K','J','Tr','P','C','D','S','O','Cm','Ediacaran','Cryogenian','Tonian'),
 young=c(0,2.58,23.04,66,143.1,201.4,251.902,298.9,358.86,419.62,443.1,486.85,538.8,635,720),
 old=c(2.58,23.04,66,143.1,201.4,251.902,298.9,358.86,419.62,443.1,486.85,538.8,635,720,1000),
 color=c('#F9F97F','#FFE619','#FD9A52','#7FC64E','#34B2C9','#812B92','#F04028','#67A599','#CB8C37','#B3E1B6','#009270','#7FA056','#FED96A','#FECC5C','#FEBF4E'))
max_age <- max(height,if(nrow(cal)) cal$max_ma else 0)*1.02
if (max_age>1000) geology <- rbind(geology,data.frame(name='Older',short='Older',young=1000,old=max_age,color='#DFE2E5'))
width <- if(is.null(opts$width)) 24 else as.numeric(opts$width)
minimum_panel_height <- max(3,1.4+nrow(cal)*.12)+4.3+5.6+2+.75+4
page_height <- if(is.null(opts$height)) max(20,n*0.15+4,minimum_panel_height) else as.numeric(opts$height)
if (any(!is.finite(c(width,page_height))) || width<12 || page_height<12) stop('PDF dimensions must be at least 12 inches.')
tree_name <- sub('\\.(nwk|tre|tree)$','',basename(opts$tree),ignore.case=TRUE)
tree_name <- sub('(\\.scientific)?\\.treePL$','',tree_name,ignore.case=TRUE)
title <- if(is.null(opts$title)) tree_name else opts$title
out <- opts$output;dir.create(dirname(out),recursive=TRUE,showWarnings=FALSE)
pdf(NULL)
tr <- ladderize(tr,right=TRUE)
plot(tr,plot=FALSE)
y <- get('last_plot.phylo',envir=.PlotPhyloEnv)$yy
x <- -ages
invisible(dev.off())
pdf_temp <- tempfile(pattern='.dated-plot-',tmpdir=dirname(out),fileext='.pdf')
pdf(pdf_temp,width=width,height=page_height,pointsize=12,family='Helvetica',useDingbats=FALSE,title=title)
par(mar=c(8,2,7,2),xaxs='i',yaxs='i',lend='round',font=2,font.axis=2,font.lab=2,fg='#27333E',col.axis='#52616E')
# Leave room for full scientific labels on the right.
small_tree <- n < 100
left_limit <- -max_age - if(small_tree) height*.9 else 0
y_limits <- if(small_tree) c(0,n+1) else c(-3,n+4)
plot.new(); plot.window(xlim=c(left_limit,height*.30),ylim=y_limits)
for(i in seq_len(nrow(geology))) {
    g<-geology[i,]; if(g$young>max_age) next
    rect(-min(g$old,max_age),-3,-g$young,n+4,col=adjustcolor(g$color,alpha.f=.055),border=NA)
}
ticks<-pretty(c(0,max_age),n=12);ticks<-ticks[ticks>=0 & ticks<=max_age]
abline(v=-ticks,col='#E4E8EA',lwd=.65)
# Keep boxes for geometry-aware placement of labels and diagnostic panels.
boxes <- matrix(numeric(),ncol=4,dimnames=list(NULL,c('x0','y0','x1','y1')))
add_box <- function(a,b,c,d) {boxes <<- rbind(boxes,c(a,b,c,d))}
hits <- function(b,obstacles=boxes) {
    if(!nrow(obstacles)) return(FALSE)
    any(b[1]<obstacles[,3] & b[3]>obstacles[,1] & b[2]<obstacles[,4] & b[4]>obstacles[,2])
}
if(nrow(cal)) for(i in seq_len(nrow(cal))) {
    yy<-y[cal$ape_node[i]]
    rect(-cal$max_ma[i],yy-.28,-cal$min_ma[i],yy+.28,col=adjustcolor('#7A7F85',alpha.f=.22),border=NA)
    add_box(-cal$max_ma[i],yy-.4,-cal$min_ma[i],yy+.4)
}
for(node in nodes) {
    cs<-children[[as.character(node)]]
    segments(x[node],min(y[cs]),x[node],max(y[cs]),col=palette[group[node]],lwd=.9)
    add_box(x[node]-.15,min(y[cs])-.15,x[node]+.15,max(y[cs])+.15)
}
for(i in seq_len(nrow(tr$edge))) {
    p<-tr$edge[i,1];ch<-tr$edge[i,2]
    segments(x[p],y[ch],x[ch],y[ch],col=palette[group[ch]],lwd=1.0)
    add_box(x[p]-.15,y[ch]-.15,x[ch]+.15,y[ch]+.15)
}
label_tip <- gsub('_',' ',tr$tip.label)
tip_colors <- vapply(palette[group[seq_len(n)]],function(z) {
    rgbv <- col2rgb(z)/255
    rgb(rgbv[1]*.72,rgbv[2]*.72,rgbv[3]*.72)
},character(1))
text(height*.007,y[seq_len(n)],label_tip,adj=c(0,.5),cex=.70,font=4,col=tip_colors)
for(i in seq_len(n)) add_box(height*.004,y[i]-.35,height*.30,y[i]+.35)
# Place compact ID / age labels without overlap. Leader lines mark displaced labels.
label_boxes <- matrix(numeric(),ncol=4)
label_positions <- matrix(NA_real_,nrow=length(nodes),ncol=2)
for(k in order(ages[nodes],y[nodes])) {
    node<-nodes[k]; lab<-sprintf('%s | %.1f',node_id[node],ages[node])
    w<-strwidth(lab,cex=.62)+height*.004; h<-strheight(lab,cex=.62)*1.25
    found<-FALSE
    for(strict in c(TRUE,FALSE)) {
    for(dy in c(.42,-.42,.8,-.8,1.2,-1.2,1.7,-1.7,2.3,-2.3,3,-3,4,-4)) {
        for(dx in c(-w/2-1,w/2+1,-w-2,w+2,0)) {
            xx<-x[node]+dx;yy<-y[node]+dy;b<-c(xx-w/2,yy-h/2,xx+w/2,yy+h/2)
            if(b[1] < -max_age || b[3]>height*.002 || b[2]<0 || b[4]>n+1) next
            if((!strict || !hits(b)) && !hits(b,label_boxes)) {found<-TRUE;break}
        }
        if(found) break
    }
    if(found) break
    }
    if(!found) stop('Cannot place node label ',node_id[node],'; increase --width or --height.')
    label_boxes<-rbind(label_boxes,b);label_positions[k,]<-c(xx,yy)
    segments(x[node],y[node],xx,yy,col='#A7ADB1',lwd=.65)
    # Conservatively reserve the connector's bounding box for inset placement.
    add_box(min(x[node],xx),min(y[node],yy),max(x[node],xx),max(y[node],yy))
    rect(b[1],b[2],b[3],b[4],col=adjustcolor('white',.93),border=NA)
    text(xx,yy,lab,cex=.62,col='#35434F')
}
boxes<-rbind(boxes,label_boxes)
if(nrow(cal)) points(x[cal$ape_node],y[cal$ape_node],pch=21,bg='#FFFFFF',col='#36434D',cex=.60,lwd=.8)
axis(1,at=-ticks,labels=ticks,cex.axis=.8,lwd=0,lwd.ticks=.6,tck=-.005)
axis(3,at=-ticks,labels=ticks,cex.axis=.8,lwd=0,lwd.ticks=.6,tck=-.005)
mtext('Millions of years before present',1,line=6.5,cex=.9)
mtext(title,3,line=5.3,adj=0,cex=1.5,font=2,col='#263846')
mtext(sprintf('%s tips  /  %s calibrations',format(n,big.mark=','),nrow(cal)),3,line=3.9,adj=0,cex=.95,col='#61727F')
# Geological strips above and below the plotting region.
par(xpd=NA)
strip_units <- diff(par('usr')[3:4])/par('pin')[2]
strip_height <- .20*strip_units
for(base in c(par('usr')[4]+.40*strip_units,par('usr')[3]-1.0*strip_units)) for(i in seq_len(nrow(geology))) {
    g<-geology[i,];if(g$young>max_age) next
    lo<- -min(g$old,max_age);hi<- -g$young
    rect(lo,base,hi,base+strip_height,col=adjustcolor(g$color,.8),border='white',lwd=.4)
    lab<-if(strwidth(g$name,cex=.65)<hi-lo-2) g$name else g$short
    if(strwidth(lab,cex=.6)<hi-lo) text((lo+hi)/2,base+strip_height/2,lab,cex=.6,col='#25333C')
}
par(xpd=FALSE)
# Find empty rectangles inside the tree's time span. Never cover a tree element.
main_fig<-par('fig');main_plt<-par('plt');main_usr<-par('usr');main_pin<-par('pin')
uy_per_inch<-diff(main_usr[3:4])/main_pin[2]
panel_locations<-list()
find_panel <- function(name,inches) {
    ph<-inches*uy_per_inch
    for(frac in if(small_tree) c(.75,.70,.65) else c(.48,.44,.40,.36)) {
        pw<-height*frac
        for(left in seq(left_limit+height*.025,if(small_tree) -max_age-height*.78 else -height*.52,length.out=15)) {
            if (ph >= diff(y_limits)) next
            for(top in seq(if(small_tree) n+.8 else n-.4,ph+if(small_tree) .2 else .4,length.out=500)) {
                b<-c(left,top-ph,left+pw,top)
                padded<-b+c(-height*.012,-.10*uy_per_inch,height*.012,.10*uy_per_inch)
                if(b[3]>-height*.12 || hits(padded)) next
                add_box(padded[1],padded[2],padded[3],padded[4]);panel_locations[[name]]<<-b;return(b)
            }
        }
    }
    stop('No clear space for ',name,' panel. Increase --height or use a less dense tree.')
}
# Place the diagnostics and their shared legend as one aligned block.
# Reserve the entire block against the tree before dividing it into panels.
panel_heights<-c(calibrations=max(3,1.4+nrow(cal)*.12),ltt=4.3,terminal=5.6,legend=2)
panel_gap<-.25
block<-find_panel('diagnostics',sum(panel_heights)+panel_gap*(length(panel_heights)-1))
panel_locations<-list();top<-block[4]
for(name in names(panel_heights)) {
    bottom<-top-panel_heights[[name]]*uy_per_inch
    panel_locations[[name]]<-c(block[1],bottom,block[3],top)
    top<-bottom-panel_gap*uy_per_inch
}
cal_box<-panel_locations$calibrations
ltt_box<-panel_locations$ltt
terminal_box<-panel_locations$terminal
legend_box<-panel_locations$legend
for (b in panel_locations) rect(b[1],b[2],b[3],b[4],col='white',border='#DEE5E9',lwd=.8)
figure_for <- function(b) {
    px<-main_plt[1]+(b[c(1,3)]-main_usr[1])/diff(main_usr[1:2])*diff(main_plt[1:2])
    py<-main_plt[3]+(b[c(2,4)]-main_usr[3])/diff(main_usr[3:4])*diff(main_plt[3:4])
    c(px,py)
}
start_panel <- function(b,mar=c(3.8,4,3.5,1.2)) {
    par(fig=figure_for(b),new=TRUE,mar=mar,xaxs='i',yaxs='i',cex=.85,mgp=c(2.2,.65,0),tcl=-.25)
}
start_panel(cal_box,mar=c(3.7,12,4.1,1))
if(nrow(cal)) {
    cc<-cal[order(cal$group,cal$estimated_age_ma,decreasing=FALSE),]
    rr<-rev(seq_len(nrow(cc)));pos<-cc$position
    limits<-range(c(-.03,1.03,pos),finite=TRUE)
    plot(NA,xlim=limits,ylim=c(.2,nrow(cc)+.8),axes=FALSE,xlab='Position within calibration range',ylab='')
    abline(v=c(0,.5,1),col=c('#BBC4CB','#E5E9EC','#BBC4CB'),lty=c(1,3,1),lwd=.8)
    segments(0,rr,1,rr,col='#E3E6E8',lwd=2)
    points(pos,rr,pch=21,bg=palette[cc$group],col=ifelse(cc$status=='outside','#C0392B','white'),cex=1.2,lwd=.5)
    fixed<-is.na(pos);if(any(fixed)) text(.5,rr[fixed],'fixed age',cex=.6)
    axis(1,at=c(0,.5,1),labels=c('Minimum','50%','Maximum'),cex.axis=.8)
    axis(2,at=rr,labels=paste(cc$node_id,gsub('_',' ',tolower(cc$node_name))),las=1,tick=FALSE,cex.axis=.64)
    mtext('01  /  Calibration-bound positions',3,line=2.3,adj=0,cex=1.1,font=2)
} else {
    plot.new();text(.5,.5,'No calibration table supplied');title('Calibration-bound positions')
}
start_panel(ltt_box)
event_ages<-sort(unique(c(height,ages[nodes],0)),decreasing=TRUE)
# Number of reconstructed extant lineages immediately younger than each event.
counts<-vapply(event_ages,function(t) sum(ages[tr$edge[,1]]>=t & ages[tr$edge[,2]]<t),integer(1))
counts[event_ages==0]<-n
plot(-event_ages,counts,type='s',log='y',axes=FALSE,xlab='Millions of years before present',ylab='Sampled lineages (log scale)',col='#314C60',lwd=2.1)
at<-pretty(c(0,height),n=5);at<-at[at<=height]
axis(1,at=-at,labels=at,cex.axis=.8);axis(2,las=1,cex.axis=.8);box(bty='l',col='#BBC4CB')
mtext('02  /  Lineages through time',3,line=2.3,adj=0,cex=1.1,font=2)
start_panel(terminal_box,mar=c(4.3,7.5,3.5,1.2))
par(cex=1.05,cex.lab=1.1)
tip_edges<-which(tr$edge[,2]<=n);duration<-tr$edge.length[tip_edges];tip_group<-group[tr$edge[tip_edges,2]]
groups<-names(palette)[names(palette) %in% tip_group]
series<-lapply(groups,function(g) duration[tip_group==g]);names(series)<-groups
boxplot(series,horizontal=TRUE,col=adjustcolor(palette[groups],.30),border=palette[groups],las=1,
        outline=FALSE,ylim=c(0,max(duration)*1.04),xlab='Terminal-branch duration (Ma)',cex.axis=1.0,boxwex=.7,lwd=1.2,yaxt='n')
axis(2,at=seq_along(groups),labels=paste0(groups,' (',lengths(series),')'),las=1,tick=FALSE,cex.axis=1.0)
for(j in seq_along(groups)) points(series[[j]],rep(j,length(series[[j]]))+seq(-.18,.18,length.out=length(series[[j]])),pch=16,cex=.6,col=adjustcolor(palette[groups[j]],.5))
mtext('03  /  Terminal-branch durations',3,line=2.3,adj=0,cex=1.3,font=2)
start_panel(legend_box,mar=c(0,0,1,0));plot.new()
legend('topleft',legend=groups,col=palette[groups],lwd=2,bty='n',ncol=3,cex=.85,title='Clade colors')
invisible(dev.off())
if (!file.rename(pdf_temp,out)) stop('Could not save final PDF: ',out)
prefix<-sub('\\.pdf$','',out,ignore.case=TRUE)
write.table(data.frame(ape_node=nodes,node_id=node_id[nodes],age_ma=ages[nodes],group=group[nodes],
                      label_x=label_positions[,1],label_y=label_positions[,2]),paste0(prefix,'.nodes.tsv'),sep='\t',row.names=FALSE,quote=FALSE)
if(nrow(cal)) write.table(cal,paste0(prefix,'.calibrations.tsv'),sep='\t',row.names=FALSE,quote=FALSE)
write.table(do.call(rbind,lapply(names(panel_locations),function(k) data.frame(panel=k,t(panel_locations[[k]])))),paste0(prefix,'.panels.tsv'),sep='\t',row.names=FALSE,quote=FALSE)
message('Created ',out,'; ',n,' tips, ',length(nodes),' node labels, ',nrow(cal),' calibration ranges. All panels occupy checked clear space.')
