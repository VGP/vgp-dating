# MD-CAT dating

[MD-CAT 1.1.15](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/README.md#use-case-4-using-calibration-ranges-with-sampling) analyses use independent calibration sampling with treePL-format configs. The annotated NEXUS trees summarize mean node ages from 100 fitted runs and 95% pooled-percentile intervals from 10,000 CI replicates. Ages and branch durations are in Ma, with extant tips at zero.

| Analysis | Matching VGP release tree |
| --- | --- |
| [ROADIES v0.0.0](roadies_v1.1.16b/README.md) | [roadies_v1.1.16b.dated.nexus](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.0.0/roadies_v1.1.16b.dated.nexus) |
| [ASTRAL v0.1.1](astralpro.l6p1/README.md) | [astralpro.l6p1.dated.nexus](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.1.1/astralpro.l6p1.dated.nexus) |

Node-age TSVs contain one row per tip or internal node. `age` is the mean; `t_lower` and `t_upper` are the 95% confidence bounds. `min` and `max` describe the range across fitted runs. `node_id` is table-specific, distinct from the APE calibration numbering; `descendant_tips` identifies clades within each topology.

## Node-age comparison

![ROADIES–ASTRAL node-age comparison](roadies_vs_astral.independent.fast95.comparison.png)

[Comparison table (TSV)](node_age_comparison.tsv)

The [ROADIES overview script](plot_roadies_mdcat.R) runs as `Rscript dating/mdcat/plot_roadies_mdcat.R` from the repository root and requires `phytools`, `plotrix`, and `png`.

[Dating overview](../README.md)
