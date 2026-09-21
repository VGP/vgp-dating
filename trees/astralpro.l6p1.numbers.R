# Number the ASTRAL-Pro tree without changing its rooting, topology, or lengths.
# Run with Rscript trees/astralpro.l6p1.numbers.R, or source from trees/.
library(ape)
args <- commandArgs(trailingOnly = FALSE)
script <- grep("^--file=", args, value = TRUE)
directory <- if (length(script)) dirname(normalizePath(sub("^--file=", "", script[1]))) else "."
path <- function(name) file.path(directory, name)

original <- read.tree(path("astralpro.l6p1.tre"))
annotations <- read.delim(path("annotations.tsv"), header = TRUE,
                          comment.char = "", stringsAsFactors = FALSE)
names(annotations)[1] <- "accession"
if (anyDuplicated(original$tip.label) || anyDuplicated(annotations$accession)) {
    stop("Duplicate tip labels or annotation accessions.")
}
lookup <- match(original$tip.label, annotations$accession)
# Explicit alias already present in annotations; do not rewrite the source tip.
alias <- which(original$tip.label == "kxProAnne1")
if (length(alias)) {
    row <- which(annotations$AssemblyId == "kxProAnne1")
    if (length(row) != 1L || annotations$accession[row] != "GCA_040939525.1") {
        stop("Expected unique kxProAnne1 alias for GCA_040939525.1.")
    }
    lookup[alias] <- row
}
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
write.tree(numbered, path("astralpro.l6p1.numbers.nwk"), digits = 17)
write.tree(named, path("astralpro.l6p1.numbers.scientific.nwk"), digits = 17)

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
reference_plot(numbered, "astralpro.l6p1.numbers.nwk.pdf", "ASTRAL-Pro l6p1 - tip identifiers and node numbers")
reference_plot(named, "astralpro.l6p1.numbers.scientific.nwk.pdf", "ASTRAL-Pro l6p1 - scientific names and node numbers")
message(Ntip(original), " tips mapped: ", length(lookup) - length(alias),
        " exact accessions and ", length(alias), " explicit AssemblyId alias; ",
        numbered$Nnode, " internal nodes numbered.")
