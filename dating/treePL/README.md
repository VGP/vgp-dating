# Exploratory treePL analyses

[treePL](https://github.com/blackrim/treePL) provides exploratory dates using [fossil constraints](../../calibrations/README.md). Released dated trees are documented under [MD-CAT](../mdcat/README.md).

## Results

Runs completed 3 November 2026 using corrected treePL, with 12 paired CV replicates and independent final fits.

| Analysis | Calibrations | Smoothing | Config | Dated tree | Calibrated ages | Figures |
| --- | ---: | ---: | --- | --- | --- | --- |
| ROADIES | 105 | 1 | [Config](roadies_v1.1.16b/roadies_v1.1.16b.config) | [Accessions](roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.tre), [names](roadies_v1.1.16b/generated/roadies_v1.1.16b.scientific.treePL.tre) | [TSV](roadies_v1.1.16b/generated/roadies_v1.1.16b.calibrated_node_ages.tsv) | [Tree](roadies_v1.1.16b/generated/roadies_v1.1.16b.dated.pdf), [optimization](roadies_v1.1.16b/generated/optimization.png) |
| ASTRAL | 100 | 0.01 | [Config](astralpro.l6p1/astralpro.l6p1.config) | [Accessions](astralpro.l6p1/generated/astralpro.l6p1.treePL.tre), [names](astralpro.l6p1/generated/astralpro.l6p1.scientific.treePL.tre) | [TSV](astralpro.l6p1/generated/astralpro.l6p1.calibrated_node_ages.tsv) | [Tree](astralpro.l6p1/generated/astralpro.l6p1.dated.pdf), [optimization](astralpro.l6p1/generated/optimization.png) |

CV scores: [ROADIES](roadies_v1.1.16b/generated/optimization.tsv), [ASTRAL](astralpro.l6p1/generated/optimization.tsv). Ages and branch lengths are in Ma. Calibration bounds are hard limits in treePL. Final-fit age differences describe numerical stability, not dating uncertainty.

The configs and benchmark use corrected treePL. A config starts a fresh fit; the saved tree may have benefited from an internally carried state and may not be reproduced exactly by running the config alone.

![ROADIES treePL timescale](roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.png)

## Run the optimizer

The standalone [script](treepl_benchmark.py) requires Python 3.9+, R with
`ape`, `ggplot2`, and `jsonlite`, and a corrected treePL build. First [build the corrected treePL](#build-treepl); the launcher does not apply the patch automatically.

Run both trees, update their configs, and regenerate all plots and tables:

```sh
python3 dating/treePL/run_all.py --treepl /path/to/corrected/treePL
```

The launcher audits calibration mappings, runs each benchmark, checks each
final tree, and stages both sets of outputs before updating the tree folders.
Use `--workers` to set concurrent workers per tree. Complete matching benchmark
results can be reused with `--results-root PATH` together with `--treepl`; the
launcher checks their input config, tree, and executable hashes.

For one arbitrary input tree, the benchmark can also be run directly:

```sh
python3 dating/treePL/treepl_benchmark.py analysis.config --output results --treepl /path/to/corrected/treePL
```
Tree paths are relative to the input config. Each invocation starts fresh in a
new output directory. `--workers` defaults to available logical CPUs minus one;
`--replicates` defaults to 12; `--seed` controls numerical and CV seeds. The combined launcher updates both configured VGP trees.

Six optimizer profiles receive four matched CV starts at smoothing 1. The
fastest profile with a training objective comparable to the best is selected.
The 11 smoothing values from 1e4 to 1e-6 are evaluated high to low with paired
held-out groups; failed or invalid CV fits are retried with the next ranked
optimizer and a new numerical seed. The smallest median CV score is selected.
At the winning value, six full-tree optimizer profiles are compared from the
same saved state, applicable full-tree detail flags are checked, and eight
independent full-tree fits are run. The best fit is saved as `dated.tre`.
The live figure and intermediate results are saved in the output directory.

`recommended.config` uses the adjacent `input.tre` and requires corrected
treePL. The config is for a fresh start; reproducing a state-carried fit exactly
would require retaining its starting state. The benchmark alone does not modify
the input config; the combined launcher updates each tree config and its
generated outputs. A successful fit is not proof of convergence.

## Build treePL

The [source patch](treepl.patch) corrects CV sampling, CV optimizer selection, gradient clipping, and annealing acceptance, and adds separate CV seeds and best-fit carryover. Build it separately from any installed treePL:

```sh
curl -L https://github.com/blackrim/treePL/archive/551cbde1a530adad7986c530ca1f254e3ffd42c7.tar.gz -o treePL.tar.gz
tar -xzf treePL.tar.gz
cd treePL-551cbde1a530adad7986c530ca1f254e3ffd42c7
patch -p1 < /absolute/path/to/vgp-dating/dating/treePL/treepl.patch
cd src
```

Tested macOS/Homebrew build, using the treePL, NLopt, and OpenMP dependencies (adjust paths and compiler flags for other systems; see the [upstream build instructions](https://github.com/blackrim/treePL)):

```sh
TREEPL_CPPFLAGS='-I/opt/homebrew/opt/treepl/libexec/include -I/opt/homebrew/opt/nlopt/include -I/opt/homebrew/opt/libomp/include'
TREEPL_LDFLAGS='-L/opt/homebrew/opt/nlopt/lib -L/opt/homebrew/opt/treepl/libexec/lib -L/opt/homebrew/opt/libomp/lib'
./configure CC=/usr/bin/clang CXX=/usr/bin/clang++ CPPFLAGS="$TREEPL_CPPFLAGS" LDFLAGS="$TREEPL_LDFLAGS"
make all -j2 CPPFLAGS="$TREEPL_CPPFLAGS" CFLAGS="$TREEPL_CPPFLAGS" LDFLAGS="$TREEPL_LDFLAGS" OPENMP='-Xpreprocessor -fopenmp -lomp'
./treePL --version
```

The version must include `vgp-optimizer-fixes-8`. Use this executable with `--treepl`; no installation step is needed. Rebuild from clean objects after changing the patch.

## Figures and checks

The [plotting script](plot_treepl.R) produces the overview, scientific-name
tree, calibration-age table, and full-tree PDF. It requires `ape`, `phytools`,
`plotrix`, and `png`. The launcher runs it for both trees. To regenerate one
set of plots manually:

```sh
Rscript dating/treePL/plot_treepl.R astralpro.l6p1
```

From the repository root, `Rscript dating/treePL/calibration_config.R` checks calibration mappings and bounds.
