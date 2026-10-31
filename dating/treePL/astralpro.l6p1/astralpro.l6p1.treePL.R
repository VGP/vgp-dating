#Visualize treePL results
# Run from dating/treePL/astralpro.l6p1/.
library(phytools)
library(plotrix)
library(png)

# read in tree
astralpro.l6p1.treePL.tre<-read.tree(file="generated/astralpro.l6p1.treePL.tre")
astralpro.l6p1.treePL.tre$node.label <- (Ntip(astralpro.l6p1.treePL.tre) + 1):(Ntip(astralpro.l6p1.treePL.tre) + astralpro.l6p1.treePL.tre$Nnode)

# Calibration nodes and bounds from the master list.
master <- read.csv("../../../calibrations/master_calibrations.csv", stringsAsFactors = FALSE)
mrca_df <- master[!is.na(master$node_astralpro_l6p1), c("calibration_id", "node_name",
  "taxon1_accession", "taxon1_name", "taxon2_accession", "taxon2_name", "min_ma", "max_ma")]
mrca_df$node <- vapply(seq_len(nrow(mrca_df)), function(i)
  getMRCA(astralpro.l6p1.treePL.tre, c(mrca_df$taxon1_accession[i], mrca_df$taxon2_accession[i])), integer(1))

# read in data
annotations <- read.delim("../../../trees/annotations.tsv", header = TRUE, comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"
# Explicit source-tree alias used only for annotations and display names.
alias <- annotations[annotations$AssemblyId == "kxProAnne1" & !is.na(annotations$AssemblyId), ]
if (nrow(alias) != 1L || alias$accession != "GCA_040939525.1") stop("Ambiguous kxProAnne1 alias.")
alias$accession <- "kxProAnne1"
annotations <- rbind(annotations, alias)
annotations <- annotations[annotations$accession %in% astralpro.l6p1.treePL.tre$tip.label, ]
if (!all(astralpro.l6p1.treePL.tre$tip.label %in% annotations$accession)) stop("Missing tip annotations.")

# add coherent taxonomy
annotations$TAXON <- annotations$VGPLineage
annotations$TAXON[which(annotations$Lineage == "Mammals")] <- "mammals"
annotations$TAXON[which(annotations$Superorder=="Actinopterygii (Ray-finned Fishes)")] <- "fishes"
annotations$TAXON[which(annotations$Superorder=="Testudines (Cryptodira)")] <- "turtles"
annotations$TAXON[which(annotations$Superorder=="Testudines (Pleurodira)")] <- "turtles"
annotations$TAXON[which(annotations$Superorder=="Crocodylia")] <- "crocs"
annotations$TAXON[which(annotations$Superorder=="Squamata")] <- "squamates"

# write scientific dates
astralpro.l6p1.scientific.treePL.tre <- astralpro.l6p1.treePL.tre
astralpro.l6p1.scientific.treePL.tre$tip.label <- gsub(" ","_",annotations$ScientificName[match(astralpro.l6p1.scientific.treePL.tre$tip.label,annotations$accession)])
duplicated_names <- duplicated(astralpro.l6p1.scientific.treePL.tre$tip.label) |
    duplicated(astralpro.l6p1.scientific.treePL.tre$tip.label, fromLast = TRUE)
astralpro.l6p1.scientific.treePL.tre$tip.label[duplicated_names] <- paste(
    astralpro.l6p1.scientific.treePL.tre$tip.label[duplicated_names],
    astralpro.l6p1.treePL.tre$tip.label[duplicated_names], sep = "_")
write.tree(astralpro.l6p1.scientific.treePL.tre, "generated/astralpro.l6p1.scientific.treePL.tre", digits = 17)

# Display the arc with fishes on the left and birds on the right.
# Reorder only the plotting copy, after writing the scientific-name tree.
astralpro.l6p1.treePL.tre <- ladderize(astralpro.l6p1.treePL.tre, right = TRUE)

# paint subtrees
painted <- paintSubTree(astralpro.l6p1.treePL.tre,Ntip(astralpro.l6p1.treePL.tre)+1,"Root","0")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="birds"),1]),
                        "Birds")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="crocs"),1]),
                        "Crocs")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="turtles"),1]),
                        "Turtles")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="squamates"),1]),
                        "Squamates")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="mammals"),1]),
                        "Mammals")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="amphibians"),1]),
                        "Amphibians")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="fishes"),1]),
                        "Fishes")
painted <- paintSubTree(painted,
                        getMRCA(astralpro.l6p1.treePL.tre,annotations[which(annotations$TAXON=="sharks"),1]),
                        "Sharks")

# clade colors
colors <- c(
  "#000000",  # black
  "#4E79A7",  # muted blue
  "#59A14F",  # muted green
  "#E15759",  # muted red
  "#F28E2B",  # muted orange
  "#B07AA1",  # muted purple
  "#76B7B2",  # muted teal
  "#EDC948",  # muted yellow
  "#9C755F"   # muted brown
)
names(colors) <- c("Root","Amphibians","Birds","Crocs","Fishes","Mammals","Sharks","Squamates","Turtles")

# save as PNG
png(
  filename = "generated/astralpro.l6p1.treePL.png",
  width = 12,
  height = 8,
  units = "in",
  res = 300
)

# plot tree as arc
arc_height<-0.4
h<-max(nodeHeights(painted))

# internal node ages (Ma), indexed by node number
bt <- branching.times(astralpro.l6p1.treePL.tre)

# match MRCA nodes to ages
mrca_df$estimated_age_ma <- bt[as.character(mrca_df$node)]

# plot tree
plotTree(astralpro.l6p1.treePL.tre,color="white",type="arc",lwd=2,ftype="off",
         arc_height=arc_height,ylim=c(-0.1*h,1.1*(1+arc_height)*h))

op <- par(mgp = c(3, 0.5, 0))  # 2nd value = tick-label distance
labs<-seq(0,h,by=50)
a1<-axis(1,pos=-0.02*h,at=h-labs+arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a1),-0.15*h,"Millions of years (Ma)",font=3)
a2<-axis(1,pos=-0.02*h,at=-h+labs-arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a2),-0.15*h,"Millions of years (Ma)",font=3)
par(op)

draw.arc(0,0,radius=h-labs[2:length(labs)]+arc_height*h,
         angle1=,angle2=pi,col=make.transparent("black",0.4),
         lty="dotted")
plot(painted,colors,type="arc",lwd=2,ftype="off",
     arc_height=arc_height,ylim=c(-0.1*h,1.1*(1+arc_height)*h),add=T)
nodelabels(node = mrca_df$node,pch = 21,bg  = "black",col = "black",cex = 0.6)
legend(x="topleft",legend=names(colors)[-1],
       pch=21,pt.cex=2.0,pt.bg=colors[-1],bty="n")
legend(x = "topright",legend = "Fossil calibrations",pch = 21,
       pt.bg = "black",col = "black",pt.cex = 1.2,bty = "n")
text(x = 0,y = -0.15 * h,labels = "Genomic timescale of\nvertebrate evolution",cex = 1.2,font = 2)

# graphics
vgp <- png::readPNG("../../assets/vgp.png")

aspect <- 842 / 352   # ≈ 2.392
img_height <- 0.3 * h     # size dial (increase/decrease here)
img_width  <- img_height * aspect
y_bottom <- -0.06 * h      # push below axes

rasterImage(
  vgp,
  xleft   = -img_width / 2,
  xright  =  img_width / 2,
  ybottom =  y_bottom,
  ytop    =  y_bottom + img_height
)

dev.off()

# Estimated ages for calibration nodes:

write.table(
  mrca_df,
  file = "generated/astralpro.l6p1.calibrated_node_ages.tsv",
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
