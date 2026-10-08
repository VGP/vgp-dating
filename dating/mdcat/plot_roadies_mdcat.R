# ROADIES MD-CAT overview for the main README.
# Run: Rscript dating/mdcat/plot_roadies_mdcat.R
# Requires phytools, plotrix, and png; no network access is needed.
# Dots use the current ROADIES mappings in master_calibrations.csv.
# Hairlines show the tree's embedded 95% pooled-percentile age intervals.
suppressPackageStartupMessages({
    library(phytools)
    library(plotrix)
    library(png)
})
script <- grep("^--file=", commandArgs(), value = TRUE)
directory <- if (length(script)) dirname(normalizePath(sub("^--file=", "", script[1]))) else "."
path <- function(name) file.path(directory, name)

# Replace internal-node annotations with temporary labels to preserve their
# association with nodes when ape reads the NEXUS tree.
source_text <- paste(readLines(path("roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre")), collapse = "\n")
locations <- gregexpr("\\)\\[&[^]]+\\]", source_text, perl = TRUE)
metadata <- regmatches(source_text, locations)[[1]]
if (!length(metadata)) stop("No internal-node age annotations found.")
field <- function(key) {
    pattern <- paste0("(?:\\[&|,)", key, "=([^,\\]]+)")
    values <- regexec(pattern, metadata, perl = TRUE)
    captures <- regmatches(metadata, values)
    if (any(lengths(captures) != 2L)) stop("Missing node annotation: ", key)
    as.numeric(vapply(captures, `[`, character(1), 2L))
}
intervals <- data.frame(mean = field("height"), lower = field("t_lower"), upper = field("t_upper"))
if (!all(grepl("CI_quantiles={0.025,0.975}", metadata, fixed = TRUE)) ||
    !all(grepl("CI_method=pooled_percentile", metadata, fixed = TRUE)))
    stop("Expected 95% pooled-percentile age intervals.")
regmatches(source_text, locations) <- list(paste0(")ci_", seq_along(metadata)))
connection <- textConnection(source_text)
tree <- read.nexus(connection)
close(connection)
tree$tip.label <- sub("^'(.*)'$", "\\1", tree$tip.label)
stopifnot(is.rooted(tree), is.ultrametric(tree), !anyDuplicated(tree$tip.label))
indices <- as.integer(sub("^ci_", "", tree$node.label))
stopifnot(length(indices) == nrow(intervals), !anyNA(indices), !anyDuplicated(indices))
ci <- intervals[indices, ]
ci$node <- seq.int(Ntip(tree) + 1L, Ntip(tree) + tree$Nnode)
tree$node.label <- as.character(ci$node)
ages <- branching.times(tree)
stopifnot(all(is.finite(as.matrix(ci))), all(ci$lower <= ci$upper),
          max(abs(ci$mean - ages[as.character(ci$node)])) < 1e-6)

master <- read.csv(path("../../calibrations/master_calibrations.csv"), stringsAsFactors = FALSE)
cal <- master[!is.na(master$node_roadies_v1_1_16b), ]
stopifnot(all(c(cal$taxon1_accession, cal$taxon2_accession) %in% tree$tip.label))
cal$node <- vapply(seq_len(nrow(cal)), function(i)
    getMRCA(tree, c(cal$taxon1_accession[i], cal$taxon2_accession[i])), integer(1))
stopifnot(all(cal$node == cal$node_roadies_v1_1_16b), !anyDuplicated(cal$node))
ci <- ci[match(cal$node, ci$node), ]

annotations <- read.delim(path("../../trees/annotations.tsv"), comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"
stopifnot(!anyDuplicated(annotations$accession), all(tree$tip.label %in% annotations$accession))
annotations <- annotations[match(tree$tip.label, annotations$accession), ]
annotations$TAXON <- annotations$VGPLineage
annotations$TAXON[annotations$Lineage == "Mammals"] <- "mammals"
annotations$TAXON[annotations$Superorder == "Actinopterygii (Ray-finned Fishes)"] <- "fishes"
annotations$TAXON[annotations$Superorder %in% c("Testudines (Cryptodira)", "Testudines (Pleurodira)")] <- "turtles"
annotations$TAXON[annotations$Superorder == "Crocodylia"] <- "crocs"
annotations$TAXON[annotations$Superorder == "Squamata"] <- "squamates"
painted <- paintSubTree(tree, Ntip(tree) + 1L, "Root", "0")
for (group in c("Birds", "Crocs", "Turtles", "Squamates", "Mammals", "Amphibians", "Fishes", "Sharks")) {
    tips <- annotations$accession[annotations$TAXON == tolower(group)]
    painted <- paintSubTree(painted, getMRCA(tree, tips), group)
}
colors <- c(Root = "#45484B", Amphibians = "#4E79A7", Birds = "#59A14F",
            Crocs = "#E15759", Fishes = "#F28E2B", Mammals = "#B07AA1",
            Sharks = "#76B7B2", Squamates = "#EDC948", Turtles = "#9C755F")
h <- max(nodeHeights(painted))
ah <- .40
vgp <- png::readPNG(path("../assets/vgp.png"))
render <- function() {
 par(mar=c(.4,.25,.3,.25),xaxs="i",yaxs="i",family="sans",fg="#44484B")
 lim<-c(-1.415*h,1.415*h); ylim<-c(-.19*h,1.41*h)
 plotTree(tree,color="white",type="arc",lwd=1,ftype="off",arc_height=ah,xlim=lim,ylim=ylim)
 labs<-seq(100,floor(h/100)*100,100)
 for(age in labs)draw.arc(0,0,radius=h-age+ah*h,angle1=0,angle2=pi,col="#E2E5E7",lwd=.65)
 plot(painted,colors,type="arc",lwd=1.15,ftype="off",arc_height=ah,xlim=lim,ylim=ylim,add=TRUE)
 nodelabels(node=cal$node,pch=16,col="#30363B",cex=.70)
 pp<-get('last_plot.phylo',envir=.PlotPhyloEnv)
 rr<-sqrt(pp$xx[ci$node]^2+pp$yy[ci$node]^2)
 stopifnot(max(abs(rr-((1+ah)*h-ci$mean)))<1e-5)
 ux<-pp$xx[ci$node]/rr;uy<-pp$yy[ci$node]/rr
 lo<-(1+ah)*h-ci$upper;hi<-(1+ah)*h-ci$lower
 segments(ux*lo,uy*lo,ux*hi,uy*hi,col='#9AA1A8',lwd=.65)
 par(mgp=c(2,.4,0))
 ticks<-seq(0,floor(h/100)*100,100)
 axis(1,pos=-.018*h,at=h-ticks+ah*h,labels=ticks,tck=-.009,cex.axis=.90,col="#B7BDC1",col.axis="#656C72",lwd=.6)
 axis(1,pos=-.018*h,at=-h+ticks-ah*h,labels=ticks,tck=-.009,cex.axis=.90,col="#B7BDC1",col.axis="#656C72",lwd=.6)
 text(0,-.150*h,"Age (Ma)",cex=1.12,col="#656C72")
 # Compact identity block inside the arc.
 rasterImage(vgp,-.34*h,.110*h,.34*h,.394*h)
 text(0,.034*h,"Genomic timescale of\nvertebrate evolution",cex=1.18,font=2,col="#343A40")
 text(0,-.057*h,"ROADIES  ·  MD-CAT",cex=1.0,col="#717980")
 legend(x=.87*h,y=.37*h,xjust=.5,yjust=1,legend=c("Amphibians","Birds","Crocs","Fishes","Mammals","Sharks","Squamates","Turtles"),col=colors[-1],pch=16,pt.cex=1.05,cex=1.00,ncol=2,bty="o",box.lwd=0,box.col=NA,bg=adjustcolor("white",alpha.f=.78),x.intersp=.65,y.intersp=1.1)
 legend(x=.87*h,y=.105*h,xjust=.5,yjust=1,legend=c("Calibrated node","95% age CI"),pch=c(16,NA),lty=c(NA,1),lwd=c(NA,.65),pt.cex=1.05,cex=.91,bty="o",box.col=NA,bg=adjustcolor("white",alpha.f=.78),text.col="#50575D",col=c("#30363B","#9AA1A8"))

}
write_plot <- function() {
    png(path("roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.png"), width = 3000,
        height = 1720, res = 230, type = "cairo")
    on.exit(dev.off())
    render()
}
write_plot()
message("Created ROADIES MD-CAT overview: ", nrow(cal), " calibration mappings with 95% age CIs.")
