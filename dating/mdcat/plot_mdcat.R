# Run: Rscript dating/mdcat/plot_mdcat.R <roadies_v1.1.16b|astralpro.l6p1|comparison> [output.png] [--strategy bottom-up]
# Dots use current master calibration mappings; hairlines show embedded 95% intervals.
suppressPackageStartupMessages({
    library(phytools)
    library(plotrix)
    library(png)
})
script <- grep("^--file=", commandArgs(), value = TRUE)
directory <- if (length(script)) dirname(normalizePath(sub("^--file=", "", script[1]))) else "."
path <- function(name) file.path(directory, name)
args <- commandArgs(trailingOnly=TRUE)
strategy <- 'independent'
if ('--strategy' %in% args) {
    i <- match('--strategy', args)
    if (i == length(args)) stop('Missing strategy.')
    strategy <- args[i+1L]; args <- args[-c(i,i+1L)]
}
if (!strategy %in% c('independent','bottom-up')) stop('Unknown strategy: ',strategy)
if (length(args)<1L || length(args)>2L) stop('Usage: plot_mdcat.R <roadies_v1.1.16b|astralpro.l6p1|comparison> [output.png] [--strategy bottom-up]')
analysis <- args[1]
if (analysis == 'comparison') {
    if (strategy != 'independent') stop('The main comparison uses independent trees.')
    compare <- function(output) {
        read_tree <- function(name) {
            tree <- read.nexus(path(file.path(name, paste0(name, '.independent.k200.round2.tre'))))
            tree$tip.label <- sub("^'(.*)'$", "\\1", tree$tip.label)
            tree$tip.label[tree$tip.label == 'kxProAnne1'] <- 'GCA_040939525.1'
            stopifnot(is.rooted(tree), is.ultrametric(tree), !anyDuplicated(tree$tip.label))
            tree
        }
        roadies <- read_tree('roadies_v1.1.16b')
        astral <- read_tree('astralpro.l6p1')
        shared <- intersect(roadies$tip.label, astral$tip.label)
        clades <- function(tree) {
            nodes <- Ntip(tree) + seq_len(tree$Nnode)
            tips <- lapply(nodes, function(node) {
                d <- getDescendants(tree, node)
                sort(intersect(tree$tip.label[d[d <= Ntip(tree)]], shared))
            })
            keys <- vapply(tips, paste, character(1), collapse = '|')
            ages <- unname(branching.times(tree)[as.character(nodes)])
            # Removing unshared tips can collapse branches: retain their shared-taxon MRCA.
            keep <- order(ages)
            keep <- keep[!duplicated(keys[keep]) & lengths(tips)[keep] >= 2L]
            list(nodes = nodes[keep], tips = tips[keep], keys = keys[keep], ages = ages[keep])
        }
        r <- clades(roadies); a <- clades(astral)
        j <- match(r$keys, a$keys); i <- which(!is.na(j)); j <- j[i]
        stopifnot(length(i) > 0L)
        result <- data.frame(roadies_node = r$nodes[i], astral_node = a$nodes[j],
            shared_taxa = lengths(r$tips)[i], roadies_ma = r$ages[i], astral_ma = a$ages[j])
        result$mean_age_ma <- (result$roadies_ma + result$astral_ma) / 2
        result$difference_ma <- result$astral_ma - result$roadies_ma
        result$absolute_difference_ma <- abs(result$difference_ma)
        stopifnot(all(is.finite(as.matrix(result))), all(result$mean_age_ma > 0))
        result$relative_difference_percent <- 100 * result$difference_ma / result$mean_age_ma
        annotations <- read.delim(path('../../trees/annotations.tsv'), comment.char = '', stringsAsFactors = FALSE)
        labels <- setNames(trimws(annotations$ScientificName), annotations[[1]])
        stopifnot(all(shared %in% names(labels)))
        result$representative_tips <- vapply(r$tips[i], function(tips)
            paste(labels[tips[c(1L, length(tips))]], collapse = ' / '), character(1))
        result <- result[order(-result$absolute_difference_ma, result$roadies_node), ]
        table <- file.path(dirname(output), 'node_age_comparison.tsv')
        write.table(result, table, sep = '\t', quote = FALSE, row.names = FALSE)
        png(output, width = 2600, height = 1250, res = 200, type = 'cairo')
        on.exit(dev.off())
        par(mfrow = c(1, 2), mar = c(4.8, 4.8, 3.5, 1.2), oma = c(0, 0, 2.2, 0),
            family = 'sans', fg = '#26364C', col.axis = '#48576B', col.lab = '#26364C')
        highlight <- seq_len(min(10L, nrow(result)))
        plot(result$roadies_ma, result$astral_ma, pch = 16, cex = .65,
            col = adjustcolor('#568F9E', alpha.f = .5), asp = 1, xaxt = 'n',
            xlab = 'ROADIES node age (Ma)', ylab = 'ASTRAL node age (Ma)',
            main = 'Equivalent clades on shared taxa')
        ticks <- pretty(range(result$roadies_ma))
        axis(1, at = ticks[ticks >= 0])
        abline(0, 1, col = '#8793A3', lty = 2)
        points(result$roadies_ma[highlight], result$astral_ma[highlight], pch = 16, col = '#E5864A', cex = .9)
        legend('topleft', bty = 'n', cex = .75, legend = c(
            sprintf('%d matched clades; %d shared taxa', nrow(result), length(shared)),
            sprintf('Median absolute difference: %.2f Ma', median(result$absolute_difference_ma)),
            'Orange: ten largest absolute differences'))
        plot(result$mean_age_ma, result$relative_difference_percent, pch = 16, cex = .65,
            col = adjustcolor('#568F9E', alpha.f = .5), xlab = 'Mean node age across trees (Ma)',
            ylab = '100 × (ASTRAL − ROADIES) / mean age', main = 'Relative age differences (%)')
        abline(h = 0, col = '#8793A3', lty = 2)
        points(result$mean_age_ma[highlight], result$relative_difference_percent[highlight],
            pch = 16, col = '#E5864A', cex = .9)
        mtext('ROADIES versus ASTRAL-Pro | independent.k200.round2', outer = TRUE, font = 2)
        message(sprintf('Created %s and %s: %d clades, %d shared taxa; median absolute difference %.6f Ma.',
            output, table, nrow(result), length(shared), median(result$absolute_difference_ma)))
    }
    compare(if (length(args) == 2L) args[2] else path('roadies_vs_astral.independent.k200.round2.comparison.png'))
    quit(save = 'no')
}
if (!analysis %in% c('roadies_v1.1.16b','astralpro.l6p1')) stop('Unknown MD-CAT tree: ',analysis)
label <- if (analysis=='astralpro.l6p1') 'ASTRAL' else 'ROADIES'
column <- if (analysis=='astralpro.l6p1') 'node_astralpro_l6p1' else 'node_roadies_v1_1_16b'
stem <- path(file.path(analysis,paste0(analysis,'.',strategy,'.k200.round2')))
output <- if(length(args)==2L) args[2] else paste0(stem,'.png')

# Replace internal-node annotations with temporary labels to preserve their
# association with nodes when ape reads the NEXUS tree.
source_text <- paste(readLines(paste0(stem,'.tre')), collapse = "\n")
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
if (strategy == 'independent') {
    nodes <- seq_len(Ntip(tree)+tree$Nnode)
    descendants <- lapply(nodes, function(node) {
        if (node <= Ntip(tree)) return(tree$tip.label[node])
        d <- getDescendants(tree,node)
        sort(tree$tip.label[d[d <= Ntip(tree)]])
    })
    result <- data.frame(node_id=nodes, label=c(tree$tip.label,tree$node.label),
        n_tips=lengths(descendants), age=c(rep(0,Ntip(tree)),ci$mean),
        t_lower=c(rep(0,Ntip(tree)),ci$lower), t_upper=c(rep(0,Ntip(tree)),ci$upper),
        n_runs=unique(field('n')), n_ci=unique(field('n_ci')),
        descendant_tips=vapply(descendants,paste,character(1),collapse='|'))
    write.table(result,paste0(stem,'.tre.tsv'),sep='\t',quote=FALSE,row.names=FALSE)
}

master <- read.csv(path("../../calibrations/master_calibrations.csv"), stringsAsFactors = FALSE)
cal <- master[!is.na(master[[column]]), ]
stopifnot(all(c(cal$taxon1_accession, cal$taxon2_accession) %in% tree$tip.label))
cal$node <- vapply(seq_len(nrow(cal)), function(i)
    getMRCA(tree, c(cal$taxon1_accession[i], cal$taxon2_accession[i])), integer(1))
stopifnot(all(cal$node == cal[[column]]), !anyDuplicated(cal$node))
ci <- ci[match(cal$node, ci$node), ]

annotations <- read.delim(path("../../trees/annotations.tsv"), comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"
if (analysis == 'astralpro.l6p1' && 'kxProAnne1' %in% tree$tip.label) {
    alias <- annotations[!is.na(annotations$AssemblyId) & annotations$AssemblyId=='kxProAnne1', ,drop=FALSE]
    if (nrow(alias)!=1L || alias$accession!='GCA_040939525.1') stop('Ambiguous kxProAnne1 alias.')
    alias$accession <- 'kxProAnne1'
    annotations <- rbind(annotations,alias)
}
stopifnot(!anyDuplicated(annotations$accession), all(tree$tip.label %in% annotations$accession))
annotations <- annotations[match(tree$tip.label, annotations$accession), ]
annotations$TAXON <- annotations$VGPLineage
annotations$TAXON[annotations$Lineage == "Mammals"] <- "mammals"
annotations$TAXON[annotations$Superorder == "Actinopterygii (Ray-finned Fishes)"] <- "fishes"
annotations$TAXON[annotations$Superorder %in% c("Testudines (Cryptodira)", "Testudines (Pleurodira)")] <- "turtles"
annotations$TAXON[annotations$Superorder == "Crocodylia"] <- "crocs"
annotations$TAXON[annotations$Superorder == "Squamata"] <- "squamates"
# Orient ASTRAL like the treePL overview while preserving node identities.
if (analysis == 'astralpro.l6p1') tree <- ladderize(tree, right=TRUE)
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
vgp <- png::readPNG(path("../vgp.png"))
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
 text(0,-.057*h,paste0(label, "  ·  MD-CAT"),cex=1.0,col="#717980")
 legend(x=.87*h,y=.37*h,xjust=.5,yjust=1,legend=c("Amphibians","Birds","Crocs","Fishes","Mammals","Sharks","Squamates","Turtles"),col=colors[-1],pch=16,pt.cex=1.05,cex=1.00,ncol=2,bty="o",box.lwd=0,box.col=NA,bg=adjustcolor("white",alpha.f=.78),x.intersp=.65,y.intersp=1.1)
 legend(x=.87*h,y=.105*h,xjust=.5,yjust=1,legend=c("Current calibration node","95% age CI"),pch=c(16,NA),lty=c(NA,1),lwd=c(NA,.65),pt.cex=1.05,cex=.91,bty="o",box.col=NA,bg=adjustcolor("white",alpha.f=.78),text.col="#50575D",col=c("#30363B","#9AA1A8"))

}
write_plot <- function() {
    png(output, width = 3000,
        height = 1720, res = 230, type = "cairo")
    on.exit(dev.off())
    render()
}
if (strategy == 'independent') {
    write_plot()
    message("Created ",label," MD-CAT overview: ", nrow(cal), " current calibration mappings with 95% age CIs: ",output)
}

# Reuse the full-tree atlas rather than maintain a second renderer.
source(path('../treePL/plot_treepl.R'), local=TRUE)
write_atlas <- function() {
    scientific <- tree
    scientific$tip.label <- gsub(' ','_',annotations$ScientificName)
    duplicate <- duplicated(scientific$tip.label) | duplicated(scientific$tip.label,fromLast=TRUE)
    scientific$tip.label[duplicate] <- paste(scientific$tip.label[duplicate],tree$tip.label[duplicate],sep='_')
    files <- replicate(3,tempfile())
    on.exit(unlink(files))
    write.tree(scientific,files[1],digits=17)
    write.tree(tree,files[2],digits=17)
    write.csv(cal,files[3],row.names=FALSE)
    make_atlas(list(tree=files[1],`accession-tree`=files[2],calibrations=files[3],
        output=paste0(stem,'.pdf'),title=paste(label,'MD-CAT |',strategy,'| k200 round 2')))
}
write_atlas()
