#Visualize treePL results
library(rphylopic)
library(phytools)
library(plotrix)
library(png)

# read in tree
roadies_v1.1.16b.treePL.tre<-read.tree(file="roadies_v1.1.16b.treePL.tre")
roadies_v1.1.16b.treePL.tre

# read in constraints
cfg <- readLines("roadies_v1.1.16b.config")

mrca_df <- do.call(
  rbind,
  lapply(
    grep("^mrca\\s*=", cfg, value = TRUE),
    function(x) {
      parts <- strsplit(x, "\\s+")[[1]]
      data.frame(
        clade = parts[3],
        tip1  = parts[4],
        tip2  = parts[5],
        stringsAsFactors = FALSE
      )
    }
  )
)

mrca_df$node <- apply(
  mrca_df[, c("tip1", "tip2")],
  1,
  function(x) getMRCA(roadies_v1.1.16b.treePL.tre, x)
)
mrca_df

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

#

# paint subtrees
painted <- paintSubTree(roadies_v1.1.16b.treePL.tre,582,"Root","0")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="birds"),1]),
                        "Birds")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="crocs"),1]),
                        "Crocs")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="turtles"),1]),
                        "Turtles")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="squamates"),1]),
                        "Squamates")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="mammals"),1]),
                        "Mammals")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="amphibians"),1]),
                        "Amphibians")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="fishes"),1]),
                        "Fishes")
painted <- paintSubTree(painted,
                        getMRCA(roadies_v1.1.16b.treePL.tre,annotations[which(annotations$TAXON=="sharks"),1]),
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

# plot tree as arc
arc_height<-0.4
h<-max(nodeHeights(painted))
plotTree(roadies_v1.1.16b.treePL.tre,color="white",type="arc",lwd=1,ftype="off",
         arc_height=arc_height,ylim=c(-0.1*h,1.1*(1+arc_height)*h))
labs<-seq(0,h,by=50)
a1<-axis(1,pos=-0.02*h,at=h-labs+arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a1),-0.2*h,"Millions of years (Ma)",font=3)
a2<-axis(1,pos=-0.02*h,at=-h+labs-arc_height*h,
         labels=labs,cex.axis=0.8,lwd=2,lend=2)
text(mean(a2),-0.2*h,"Millions of years (Ma)",font=3)
draw.arc(0,0,radius=h-labs[2:length(labs)]+arc_height*h,
         angle1=,angle2=pi,col=make.transparent("black",0.4),
         lty="dotted")
plot(painted,colors,type="arc",lwd=1,ftype="off",
     arc_height=arc_height,ylim=c(-0.1*h,1.1*(1+arc_height)*h),add=T)
nodelabels(node = mrca_df$node,pch = 21,bg  = "black",col = "black",cex = 0.6)
legend(x="topleft",legend=names(colors)[-1],
       pch=21,pt.cex=2.0,pt.bg=colors[-1],bty="n")
legend(x = "topright",legend = "Fossil calibrations",pch = 21,
       pt.bg = "black",col = "black",pt.cex = 1.2,bty = "n")
text(x = 0,y = -0.15 * h,labels = "Timescale of\nvertebrate evolution",cex = 1.2,font = 2)

# graphics
vgp <- png::readPNG("vgp.png")

aspect <- 842 / 352   # ≈ 2.392
img_height <- 0.28 * h     # size dial (increase/decrease here)
img_width  <- img_height * aspect
y_bottom <- -0.06 * h      # push below axes

rasterImage(
  vgp,
  xleft   = -img_width / 2,
  xright  =  img_width / 2,
  ybottom =  y_bottom,
  ytop    =  y_bottom + img_height
)

# dunkleosteus
dunkleosteus <- get_phylopic("ac582db2-b8b7-45c1-a266-e33f0480addc")
add_phylopic_base(
  img    = dunkleosteus,
  x      = -775,
  y      = 1.05 * h,
  height = 0.175 * h,   # (preferred in newer versions)
  col    = "lightgrey",
  fill   = "lightgrey"
)

# tiktaalik
tiktaalik <- get_phylopic("10a9bdee-2c86-4f13-a8ae-5ff92dbed2a9")
add_phylopic_base(
  img    = tiktaalik,
  x      = -500,
  y      = 1.4 * h,
  height = 0.1 * h,   # (preferred in newer versions)
  col    = "lightgrey",
  fill   = "lightgrey"
)

# dimetrodon
dimetrodon <- get_phylopic("b9b73c89-7609-4524-b068-7c7c7f566979")
add_phylopic_base(
  img    = dimetrodon,
  x      = -0,
  y      = 1.6 * h,
  height = 0.3 * h,   # (preferred in newer versions)
  col    = "lightgrey",
  fill   = "lightgrey"
)

# proganochelys
proganochelys <- get_phylopic("f41ef99b-c2b8-49ca-be59-8b2b5a47e57f")
add_phylopic_base(
  img    = proganochelys,
  x      = 500,
  y      = 1.4 * h,
  height = 0.2 * h,   # (preferred in newer versions)
  col    = "lightgrey",
  fill   = "lightgrey"
)

# archaeopteryx
archaeopteryx <- get_phylopic("045279d5-24e5-4838-bec9-0bea86812e35")
add_phylopic_base(
  img    = archaeopteryx,
  x      = 800,
  y      = 0.95 * h,
  height = 0.25 * h,   # (preferred in newer versions)
  col    = "lightgrey",
  fill   = "lightgrey"
  )
