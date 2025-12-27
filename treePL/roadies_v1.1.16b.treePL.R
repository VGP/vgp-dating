#Visualize treePL results
library(phytools)
library(plotrix)

# read in tree
roadies_v1.1.16b.treePL.tre<-read.tree(file="roadies_v1.1.16b.treePL.tre")
roadies_v1.1.16b.treePL.tre

# read in data
annotations <- read.delim("annotations.tsv", header = TRUE, comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"

# add coherent taxonomy
annotations$TAXON <- annotations$VGPLineage
annotations$TAXON[which(annotations$Superorder=="Actinopterygii (Ray-finned Fishes)")] <- "fishes"
annotations$TAXON[which(annotations$Superorder=="Testudines (Cryptodira)")] <- "turtles"
annotations$TAXON[which(annotations$Superorder=="Testudines (Pleurodira)")] <- "turtles"
annotations$TAXON[which(annotations$Superorder=="Crocodylia")] <- "crocs"
annotations$TAXON[which(annotations$Superorder=="Squamata")] <- "squamates"

# paint subtrees
painted <- paintSubTree(roadies_v1.1.16b.treePL.tre,582,"root","0")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="birds"),1]),
                        "birds")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="crocs"),1]),
                        "crocs")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="turtles"),1]),
                        "turtles")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="squamates"),1]),
                        "squamates")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="mammals"),1]),
                        "mammals")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="amphibians"),1]),
                        "amphibians")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="fishes"),1]),
                        "fishes")
painted <- paintSubTree(painted,
                        getMRCA(roadies,annotations[which(annotations$TAXON=="sharks"),1]),
                        "sharks")

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
names(colors) <- c("root","amphibians","birds","crocs","fishes","mammals","sharks","squamates","turtles")

# plot tree as arc
arc_height<-0.4
h<-max(nodeHeights(painted))
plot(painted,colors,type="arc",lwd=1,fsize=0.01,ftype="i",
         arc_height=arc_height,ylim=c(-0.1*h,1.1*(1+arc_height)*h))
labs<-seq(0,h,by=50)
a1<-axis(1,pos=-0.02*h,at=h-labs+arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a1),-0.23*h,"Million Years (Ma)",font=3)
a2<-axis(1,pos=-0.02*h,at=-h+labs-arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a2),-0.23*h,"Million Years (Ma)",font=3)
draw.arc(0,0,radius=h-labs[2:length(labs)]+arc_height*h,
         angle1=,angle2=pi,col=make.transparent("black",0.4),
         lty="dotted")
legend(x="topleft",legend=names(colors),
       pch=21,pt.cex=2.5,pt.bg=colors,bty="n")
