# MD-CAT dating

Analyses used [MD-CAT 1.1.15](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/README.md#use-case-4-using-calibration-ranges-with-sampling) with independent calibration sampling and treePL-format configs. Node ages are means across 100 fitted runs, with 95% pooled-percentile intervals from 10,000 CI replicates. Ages and branch lengths are in Ma.

## Analyses

| Commands and files | VGP release tree |
| --- | --- |
| [ROADIES v0.0.0](roadies_v1.1.16b/README.md) | [NEXUS](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.0.0/roadies_v1.1.16b.dated.nexus) |
| [ASTRAL v0.1.1](astralpro.l6p1/README.md) | [NEXUS](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.1.1/astralpro.l6p1.dated.nexus) |

## Node-age tables

TSV files contain mean ages (`age`), 95% confidence bounds (`t_lower`, `t_upper`), and ranges across fitted runs (`min`, `max`) for each tip and internal node. Table-specific `node_id` values differ from APE calibration numbers; `descendant_tips` identifies clades within each topology.

## Node-age comparison

![ROADIES–ASTRAL node-age comparison](roadies_vs_astral.independent.fast95.comparison.png)

[Comparison table (TSV)](node_age_comparison.tsv)

[Dating overview](../README.md)
