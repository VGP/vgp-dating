# MD-CAT dating

[Dating overview](../README.md) · [ROADIES run record](roadies_v1.1.16b/README.md) · [ASTRAL run record](astralpro.l6p1/README.md)

Siavash Mirarab supplied the commands recorded on the two analysis pages and reported **MD-CAT 1.1.15** for both runs. The [sampling-driver documentation](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/README.md#use-case-4-using-calibration-ranges-with-sampling) describes `md_cat_sample.py`. The source at that revision reports version 1.1.15; the exact checkout used for these runs remains to be recorded.

## Calibration configs and commands

MD-CAT accepts the treePL-format configs directly through `-t`, including their `mrca`, `min`, and `max` entries. The sampling driver also uses `numsites` and `seed` when the corresponding command-line options are omitted, and `nthreads` when `--threads` is omitted. The input tree is supplied through `-i`; treePL smoothing and optimizer settings do not control MD-CAT. See the [calibration parser](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/emd/calibration.py) and [sampling driver](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/emd/sample.py).

The analysis pages link the existing repository configs. Their calibration entries agree with the current [master calibration list](../../calibrations/master_calibrations.csv). Confirm the configs and seeds used for the original MD-CAT runs against their saved run directories before treating these current files as exact run snapshots. The directory reorganization changed only the input-tree paths and calibration-source comments in the live configs.

Both supplied commands use `--strategy independent`, `--jobs 100`, `--threads 1`, `--CI "100 0.025 0.975"`, and `--max-draws 1000000000`. Here `independent` selects the calibration-sampling strategy. The retained outputs report mean node ages across 100 fitted runs and 95% pooled-percentile intervals from 10,000 CI replicates. Ages, age summaries, and branch durations are in Ma, with present-day tips at zero.

## Files and release correspondence

The `.tre` files here contain annotated **NEXUS** trees. Their annotations include mean ages and confidence bounds. The VGP release also offers plain Newick versions without these annotations.

| Analysis | Local dated tree | Matching release file |
| --- | --- | --- |
| ROADIES | [roadies_v1.1.16b.independent.fast95.tre](roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre) | [v0.0.0/roadies_v1.1.16b.dated.nexus](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.0.0/roadies_v1.1.16b.dated.nexus) |
| ASTRAL | [astralpro.l6p1.independent.fast95.tre](astralpro.l6p1/astralpro.l6p1.independent.fast95.tre) | [v0.1.1/astralpro.l6p1.dated.nexus](https://github.com/VGP/vgp-tree-release/blob/0eb651ea1a87467788370d1e72b115447c724207/v0.1.1/astralpro.l6p1.dated.nexus) |

Both local dated trees and both reference input trees were verified byte-for-byte against release commit `0eb651ea1a87467788370d1e72b115447c724207` on 2026-10-08. Local filenames are retained to preserve their association with the supplied tables and figures.

## Node-age tables

The original tab-separated `.tre.tsv` files contain one row per tip or internal node: 1,161 rows for ROADIES (581 tips, 580 internal nodes) and 1,129 for ASTRAL (565 tips, 564 internal nodes). Their age estimates and confidence bounds agree with the corresponding NEXUS annotations within serialization precision (less than `1e-9` Ma).

| Column(s) | Meaning |
| --- | --- |
| `node_id` | Identifier within this MD-CAT summary table. It is not the APE node number used in the calibration master. |
| `label` | Node label retained from the summarized tree; tip labels identify the sampled assemblies. |
| `n_tips`, `descendant_tips` | Number of descendant tips and their identifiers as a JSON array. Use descendant-tip sets to match nodes within a topology. |
| `statistic`, `age` | Summary statistic and resulting age; both tables use the mean. |
| `n_runs` | Number of fitted runs contributing to the summary: 100. |
| `mean`, `sd`, `min`, `max` | Mean, sample standard deviation, and range of the node-age estimates across fitted runs. These extrema are not calibration bounds or CI endpoints. |
| `t_lower`, `t_upper` | Lower and upper pooled-percentile confidence bounds. |
| `ci_lower_quantile`, `ci_upper_quantile` | CI quantiles: 0.025 and 0.975. |
| `n_ci` | Number of pooled CI replicates: 10,000. |

Column definitions follow the [MD-CAT summary writer](https://github.com/smirarab/MD-Cat/blob/deafdab1e657d3e807b5e8203f3ee5189131b0e5/emd/summary.py). For comparisons across topologies, account for different tip sampling and clade membership rather than joining on numeric node IDs.

## Completing the run records

The most useful additions from the original run directories are `manifest.json`, `calibrations.config`, and the summary `.tre.json` files, together with the software checkout, execution date, and environment details. These establish the actual seeds, settings, and input/config hashes. Retain relevant logs if available. For ASTRAL, also document the initial run and how the resumed `fastcorrect` output became the retained `fast95` file. Add these details beside each analysis; the recorded commands remain as supplied rather than being rewritten into an unverified rerun recipe.

## Visualizations

The overview figure is generated by [plot_roadies_mdcat.R](plot_roadies_mdcat.R). From the repository root, run `Rscript dating/mdcat/plot_roadies_mdcat.R`; it requires `phytools`, `plotrix`, and `png`. The figure marks current calibration mappings and displays their embedded 95% age CIs.

The existing [comparison figure](roadies_vs_astral.independent.fast95.comparison.png) and [comparison table](node_age_comparison.tsv) are retained alongside the two analyses.
