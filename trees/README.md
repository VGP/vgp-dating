# Tree visualizations

These are adaptations of the [ROADIES v0.0.0](./roadies_v1.1.16b.nwk) and [ASTRAL v0.1.1](./astralpro.l6p1.tre) trees to add node numbers and other visual aids. For each tree, `.numbers` and `.numbers.scientific` files provide node numbers with accession and scientific-name tips, respectively, in both Newick and PDF. The PDFs are cladograms for assigning calibrations across clades with an internally consistent numbering system for each tree; the Newick files retain the original branch lengths.

| Tree | Accession labels | Scientific-name labels | Numbering script |
| --- | --- | --- | --- |
| ROADIES v0.0.0 | [Newick](roadies_v1.1.16b.numbers.nwk) · [PDF](roadies_v1.1.16b.numbers.nwk.pdf) | [Newick](roadies_v1.1.16b.numbers.scientific.nwk) · [PDF](roadies_v1.1.16b.numbers.scientific.nwk.pdf) | [R script](roadies_v1.1.16b.numbers.R) |
| ASTRAL v0.1.1 | [Newick](astralpro.l6p1.numbers.nwk) · [PDF](astralpro.l6p1.numbers.nwk.pdf) | [Newick](astralpro.l6p1.numbers.scientific.nwk) · [PDF](astralpro.l6p1.numbers.scientific.nwk.pdf) | [R script](astralpro.l6p1.numbers.R) |

The [annotation table](annotations.tsv) supplies the tip labels used by both numbering scripts.

Annotation additions for ASTRAL were verified against NCBI: [GCA_000001405.5, Homo sapiens GRCh37.p4](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000001405.5/), [GCA_000001635.9, Mus musculus GRCm39](https://www.ncbi.nlm.nih.gov/datasets/genome/GCA_000001635.9/), and [GCF_037038585.1, Patagioenas fasciata bPatFas1.hap1](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_037038585.1/). Their species-level fields reuse the existing same-species annotation rows; `AssemblyId` records the verified assembly name, while unverified `asmId` and `UCSC_comName` fields are blank. Existing rows are preserved.

The ASTRAL script explicitly maps `kxProAnne1` through the existing `AssemblyId` field to the `GCA_040939525.1` annotation row for _Protopterus annectens_, retaining `kxProAnne1` as the original tip identifier. Human and mouse each have two tips; both members of each duplicate scientific-name pair receive their original accession suffix. These mappings are for labels only and do not substitute defining taxa in calibrations.

## Dated trees

MD-CAT dated trees, node-age tables, figures, and run records for ROADIES v0.0.0 and ASTRAL v0.1.1 are available in [dating](../dating/README.md). This folder retains the reference topologies, tip annotations, and node-numbering files used to assign calibrations.
