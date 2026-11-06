# VGP Phase I dated trees

We dated the ROADIES v0.0.0 and ASTRAL v0.1.1 trees with [MD-CAT](https://github.com/smirarab/MD-Cat), repeating the analysis with ages sampled from the fossil calibration distributions. Independent sampling draws each calibration age separately, redrawing incompatible ages. Bottom-up sampling starts with descendant nodes and raises the minimum age for an ancestral calibration when necessary to accommodate its descendants. This can shift ages older, particularly where several calibrations are nested. We use the independent trees for the main results and checkpoint comparisons, and provide the bottom-up trees as alternatives.

Reported node ages are means across 100 fitted runs, with 95% pooled-percentile intervals calculated from 10,000 confidence-interval replicates. Ages and branch lengths are in **millions of years (Ma)**.

The [calibration documentation](../calibrations/README.md) provides the fossil justifications. The [master list](../calibrations/master_calibrations.csv) contains 108 constraints, with 105 mapped to ROADIES, 100 to ASTRAL, and 97 shared. The [reference-tree documentation](../trees/README.md) describes the undated topologies, annotations, and APE node-numbering files.

## Dated trees

| Reference tree | Tips | Inputs | Independent | Node ages | Bottom-up |
| --- | ---: | --- | --- | --- | --- |
| [ROADIES v0.0.0](https://github.com/VGP/vgp-tree-release/tree/master/v0.0.0) | 581 | [Tree](../trees/roadies_v1.1.16b.nwk), [calibrations](treePL/roadies_v1.1.16b/roadies_v1.1.16b.config) | [NEXUS](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.k200.round2.tre), [PDF](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.k200.round2.pdf), [PNG](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.k200.round2.png) | [TSV](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.k200.round2.tre.tsv) | [NEXUS](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.bottom-up.k200.round2.tre), [PDF](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.bottom-up.k200.round2.pdf) |
| [ASTRAL v0.1.1](https://github.com/VGP/vgp-tree-release/tree/master/v0.1.1) | 565 | [Tree](../trees/astralpro.l6p1.tre), [calibrations](treePL/astralpro.l6p1/astralpro.l6p1.config) | [NEXUS](mdcat/astralpro.l6p1/astralpro.l6p1.independent.k200.round2.tre), [PDF](mdcat/astralpro.l6p1/astralpro.l6p1.independent.k200.round2.pdf), [PNG](mdcat/astralpro.l6p1/astralpro.l6p1.independent.k200.round2.png) | [TSV](mdcat/astralpro.l6p1/astralpro.l6p1.independent.k200.round2.tre.tsv) | [NEXUS](mdcat/astralpro.l6p1/astralpro.l6p1.bottom-up.k200.round2.tre), [PDF](mdcat/astralpro.l6p1/astralpro.l6p1.bottom-up.k200.round2.pdf) |

![ROADIES MD-CAT timescale](mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.k200.round2.png)

Overview dots mark the calibration nodes, and hairlines show the 95% age intervals. Full-tree PDFs label species and internal nodes, with calibration bounds and age summaries. Node-age tables contain one row per tip or internal node, using APE node numbers. Columns give the mean age (`age`), 95% bounds (`t_lower`, `t_upper`), numbers of fitted runs and confidence-interval replicates, and descendant accessions (`descendant_tips`).

## Node-age comparison

The comparison matches 548 clades among the 562 taxa shared by ROADIES and ASTRAL. The left panel compares their mean node ages against a line of equality. The right panel shows `100 × (ASTRAL − ROADIES) / mean age`; positive values indicate older ASTRAL estimates. Orange points mark the ten largest absolute differences.

![ROADIES–ASTRAL node-age comparison](mdcat/roadies_vs_astral.independent.k200.round2.comparison.png)

The [comparison table](mdcat/node_age_comparison.tsv) lists the paired nodes, ages, differences, and representative tips.

## Regenerate figures and tables

The [plotting script](mdcat/plot_mdcat.R) updates the independent overview, full-tree PDF, and node-age table for either topology, or the comparison:

```sh
Rscript dating/mdcat/plot_mdcat.R roadies_v1.1.16b
Rscript dating/mdcat/plot_mdcat.R astralpro.l6p1
Rscript dating/mdcat/plot_mdcat.R comparison
```

Add `--strategy bottom-up` to either tree command to produce its alternative full-tree PDF.

## Exploratory analyses

[treePL analyses](treePL/README.md) provide exploratory dates, with a standalone optimizer and configs.
