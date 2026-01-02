# add node numbers to roadies_v1.1.16b.nwk
library(ape)

# read in tree
roadies_v1.1.16b.nwk <- read.tree("roadies_v1.1.16b.nwk")
plot(roadies_v1.1.16b.nwk)
nodelabels()

# read in data
annotations <- read.delim("annotations.tsv", header = TRUE, comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"

# write node numbers - accession
nn <- roadies_v1.1.16b.nwk$Nnode
roadies_v1.1.16b.numbers.nwk <- roadies_v1.1.16b.nwk
roadies_v1.1.16b.numbers.nwk$node.label <- as.character((Ntip(roadies_v1.1.16b.numbers.nwk) + 1):(Ntip(roadies_v1.1.16b.numbers.nwk) + nn))
write.tree(roadies_v1.1.16b.numbers.nwk, "roadies_v1.1.16b.numbers.nwk")

# write node numbers - scientific
roadies_v1.1.16b.numbersScientific.nwk <- roadies_v1.1.16b.numbers.nwk
roadies_v1.1.16b.numbersScientific.nwk$tip.label <- gsub(" ","_",annotations$ScientificName[match(roadies_v1.1.16b.numbers.nwk$tip.label,annotations$accession)])
write.tree(roadies_v1.1.16b.numbersScientific.nwk, "roadies_v1.1.16b.numbersScientific.nwk")
