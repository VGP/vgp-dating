# Likelihood checkpoints

These figures compare published divergence-time estimates with the released ROADIES and ASTRAL MD-CAT trees. Vertical lines show the age of the specified taxon pair and current fossil calibration bounds. The released MD-CAT trees used an earlier calibration set, so their ages do not reflect all current bounds. A checkpoint is a comparison with published estimates, not an independent test when studies share data or calibrations.

![Overview of likelihood checkpoints](checkpoints_summary.png)

The overview plots all available point estimates together, including those from fossil-inclusive analyses. It can be regenerated with `Rscript calibrations/plot_checkpoint_summary.R`.

| Clade | Checkpoint |
| --- | --- |
| Deuterostomia | [Clade page and figure](outgroups/deuterostomia.md#likelihood-checkpoints) |
| Vertebrata | [Clade page and figure](vertebrates/vertebrata.md#likelihood-checkpoints) |
| Teleostei | [Clade page and figure](fishes/fishes.md#likelihood-checkpoints) |
| Tetrapoda | [Clade page and figure](tetrapods/tetrapoda.md#likelihood-checkpoints) |
| Amphibia | [Clade page and figure](amphibia/amphibia.md#likelihood-checkpoints) |
| Squamata | [Clade page and figure](squamata/squamata.md#likelihood-checkpoints) |
| Testudines | [Clade page and figure](turtles/testudines.md#likelihood-checkpoints) |
| Crocodylia | [Clade page and figure](crocodylia/crocodylia.md#likelihood-checkpoints) |
| Mammalia | [Clade page and figure](mammals/mammalia.md#likelihood-checkpoints) |

All checkpoint records are in [checkpoint_estimates.csv](checkpoint_estimates.csv), including the previously compiled datasets and the four new TimeTree exports. Rows contain estimates, available intervals and citations. Citation information is incomplete, and node equivalence has not yet been independently verified. TimeTree pairwise entries may include study-level estimates for related sampled taxa, rather than an analysis containing both exact species. The four new figures can be regenerated from the repository root with `Rscript calibrations/plot_checkpoints.R`.

Earlier checkpoints retain their existing plotting scripts, linked on their clade pages; these now read the shared table. See [PhyloPic credits](PHYLOPIC_CREDITS.md) for the silhouettes in the new figures.
