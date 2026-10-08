# VGP Phase I dated trees

The available ROADIES v0.0.0 and ASTRAL v0.1.1 dated trees were inferred using **MD-CAT 1.1.15**, with fossil-calibration ranges assembled by the VGP dating working group. Ages and dated branch lengths are in **millions of years (Ma)**.

The [VGP tree-release repository](https://github.com/VGP/vgp-tree-release) distributes the trees. This repository records their calibration sources, dating commands, node-age tables, and visualizations.

## Trees and run records

| Reference tree | Dating methods and commands | Dated tree (NEXUS) | Node-age table (TSV) | Figure | Release |
| --- | --- | --- | --- | --- | --- |
| ROADIES v0.0.0 | [Run record](mdcat/roadies_v1.1.16b/README.md) | [Tree](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre) | [Table](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre.tsv) | [PDF](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.pdf) | [v0.0.0](https://github.com/VGP/vgp-tree-release/tree/master/v0.0.0) |
| ASTRAL v0.1.1 | [Run record](mdcat/astralpro.l6p1/README.md) | [Tree](mdcat/astralpro.l6p1/astralpro.l6p1.independent.fast95.tre) | [Table](mdcat/astralpro.l6p1/astralpro.l6p1.independent.fast95.tre.tsv) | [PDF](mdcat/astralpro.l6p1/astralpro.l6p1.independent.fast95.pdf) | [v0.1.1](https://github.com/VGP/vgp-tree-release/tree/master/v0.1.1) |

See the [MD-CAT methods and file guide](mdcat/README.md) for configuration handling, table columns, and the correspondence between local and release filenames. A comparison of the two analyses is available as a [figure](mdcat/roadies_vs_astral.independent.fast95.comparison.png) and [node-age table](mdcat/node_age_comparison.tsv).

![ROADIES MD-CAT timescale](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.png)

## Calibrations and reference trees

The [calibration documentation](../calibrations/calibrations.md) provides the fossil justifications. The [master calibration list](../calibrations/master_calibrations.csv) contains 99 records, with 96 mapped to ROADIES, 91 to ASTRAL, and 88 shared. The [reference-tree documentation](../trees/trees.md) describes the undated topologies, annotations, and APE node-numbering files used by contributors.

## Exploratory analyses

Earlier [treePL tests](treePL/README.md), including their scripts, configs, and generated results, are retained for reference.
