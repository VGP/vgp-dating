# Tree visualizations

These are adaptations of the [ROADIES v0.0.0](./roadies_v1.1.16b.nwk) and [ASTRAL v0.1.1 per-species](./astralpro.l6p1.perspecies.tre) trees to add node numbers and other visual aids. For each tree, `.numbers` and `.numbers.scientific` files provide node numbers with accession and scientific-name tips, respectively, in both Newick and PDF. The PDFs are cladograms for assigning calibrations across clades with an internally consistent numbering system for each tree; the Newick files retain the original branch lengths. The [annotation table](annotations.tsv) supplies the tip labels used by both numbering scripts. MD-CAT dated trees, node-age tables, and figures for both trees are available in [dating](../dating/README.md).

| Tree | Accession labels | Scientific-name labels | Numbering script |
| --- | --- | --- | --- |
| ROADIES v0.0.0 | [Newick](roadies_v1.1.16b.numbers.nwk) · [PDF](roadies_v1.1.16b.numbers.nwk.pdf) | [Newick](roadies_v1.1.16b.numbers.scientific.nwk) · [PDF](roadies_v1.1.16b.numbers.scientific.nwk.pdf) | [R script](roadies_v1.1.16b.numbers.R) |
| ASTRAL v0.1.1 per-species | [Newick](astralpro.l6p1.perspecies.numbers.nwk) · [PDF](astralpro.l6p1.perspecies.numbers.nwk.pdf) | [Newick](astralpro.l6p1.perspecies.numbers.scientific.nwk) · [PDF](astralpro.l6p1.perspecies.numbers.scientific.nwk.pdf) | [R script](astralpro.l6p1.perspecies.numbers.R) |


The ASTRAL per-species tree contains 563 tips, retaining one human (`GCA_009914755.4`) and one mouse (`GCA_949316315.1`). It differs from the original 565-tip release only by removal of the other human and mouse tips; the remaining topology and branch lengths are unchanged. Its node numbers have been regenerated accordingly.

The ASTRAL script maps `kxProAnne1` through the existing `AssemblyId` field to the `GCA_040939525.1` annotation row for _Protopterus annectens_, retaining `kxProAnne1` as the original tip identifier. This mapping is for display labels only and does not substitute defining taxa in calibrations.
