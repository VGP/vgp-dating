# Number the ROADIES tree without changing its rooting, topology, or lengths.
# Run with Rscript trees/roadies_v1.1.16b.numbers.R, or source from trees/.
library(ape)
args <- commandArgs(trailingOnly = FALSE)
script <- grep("^--file=", args, value = TRUE)
directory <- if (length(script)) dirname(normalizePath(sub("^--file=", "", script[1]))) else "."
path <- function(name) file.path(directory, name)

original <- read.tree(path("roadies_v1.1.16b.nwk"))
annotations <- read.delim(path("annotations.tsv"), header = TRUE,
                          comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"
if (!"ScientificName" %in% names(annotations)) stop("Missing ScientificName annotation column.")
if (anyDuplicated(original$tip.label) || anyDuplicated(annotations$accession)) {
    stop("Duplicate tip labels or annotation accessions.")
}
lookup <- match(original$tip.label, annotations$accession)
if (anyNA(lookup)) stop("Missing annotations: ", paste(original$tip.label[is.na(lookup)], collapse = ", "))
scientific <- annotations$ScientificName[lookup]
if (anyNA(scientific) || any(!nzchar(trimws(scientific)))) stop("Missing scientific names.")
scientific <- gsub(" ", "_", scientific)
repeated <- duplicated(scientific) | duplicated(scientific, fromLast = TRUE)
scientific[repeated] <- paste(scientific[repeated], original$tip.label[repeated], sep = "_")
if (anyDuplicated(scientific)) stop("Scientific tip labels are not unique.")

numbered <- original
numbered$node.label <- as.character(seq.int(Ntip(numbered) + 1L, Ntip(numbered) + numbered$Nnode))
named <- numbered
named$tip.label <- scientific
# digits=17 retains the source branch-length precision in the derived files.
write.tree(numbered, path("roadies_v1.1.16b.numbers.nwk"), digits = 17)
write.tree(named, path("roadies_v1.1.16b.numbers.scientific.nwk"), digits = 17)

reference_plot <- function(tree, filename, title) {
    # Tall vector page for inspecting every tip and internal-node number at zoom.
    pdf(path(filename), width = 20, height = max(12, Ntip(tree) * 0.16),
        useDingbats = FALSE, title = title)
    on.exit(dev.off())
    par(mar = c(1, 1, 3, 1))
    plot(tree, use.edge.length = FALSE, node.depth = 2, cex = 0.7, no.margin = FALSE,
         main = title, font = 1)
    nodelabels(text = tree$node.label, frame = "none", cex = 0.5,
               adj = c(1.1, -0.25), col = "#245A81")
    mtext("Cladogram for node reference; branch lengths retained in Newick files.", side = 3, line = 0.3, cex = 0.8)
}
reference_plot(numbered, "roadies_v1.1.16b.numbers.nwk.pdf", "ROADIES v1.1.16b - tip identifiers and node numbers")
reference_plot(named, "roadies_v1.1.16b.numbers.scientific.nwk.pdf", "ROADIES v1.1.16b - scientific names and node numbers")
message(Ntip(original), " tips mapped to exact accessions; ",
        numbered$Nnode, " internal nodes numbered.")
