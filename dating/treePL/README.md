# Exploratory treePL analyses

[treePL](https://github.com/blackrim/treePL) provides exploratory dates using [fossil constraints](../../calibrations/README.md). Released dated trees are documented under [MD-CAT](../mdcat/README.md).

## Results

Runs completed 31 October 2026 using corrected treePL, with eight paired CV replicates and independent final fits. These results predate CAL106 (†_Eosalmo_). The linked configs now contain 103 ROADIES and 98 ASTRAL constraints; the optimization and dating runs have not yet been repeated with CAL106.

| Analysis | Calibrations used | Smoothing | Current config | Dated tree | Calibrated ages | Figures |
| --- | ---: | ---: | --- | --- | --- | --- |
| ROADIES | 102 | 1.77828 | [Config](roadies_v1.1.16b/roadies_v1.1.16b.config) | [Accessions](roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.tre), [names](roadies_v1.1.16b/generated/roadies_v1.1.16b.scientific.treePL.tre) | [TSV](roadies_v1.1.16b/generated/roadies_v1.1.16b.calibrated_node_ages.tsv) | [Tree](roadies_v1.1.16b/generated/roadies_v1.1.16b.dated.pdf), [optimization](roadies_v1.1.16b/generated/optimization.png) |
| ASTRAL | 97 | 1e-8 | [Config](astralpro.l6p1/astralpro.l6p1.config) | [Accessions](astralpro.l6p1/generated/astralpro.l6p1.treePL.tre), [names](astralpro.l6p1/generated/astralpro.l6p1.scientific.treePL.tre) | [TSV](astralpro.l6p1/generated/astralpro.l6p1.calibrated_node_ages.tsv) | [Tree](astralpro.l6p1/generated/astralpro.l6p1.dated.pdf), [optimization](astralpro.l6p1/generated/optimization.png) |

CV scores: [ROADIES](roadies_v1.1.16b/generated/optimization.tsv), [ASTRAL](astralpro.l6p1/generated/optimization.tsv). Ages and branch lengths are in Ma. Calibration bounds are hard limits in treePL. Final-fit age differences describe numerical stability, not dating uncertainty.

The configs run with stock treePL from their analysis directories. The dated trees use the corrected optimizer; stock runs can give different ages.

![ROADIES treePL timescale](roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.png)

## Run the optimizer

The standalone [script](treepl_benchmark.py) requires Python 3.9+, R with `ape`, the corrected treePL build below, and stock treePL to check exported configs.

```sh
python3 treepl_benchmark.py analysis.config --output results --treepl /path/to/corrected/treePL --stock-treepl /path/to/stock/treePL
```

Tree paths are relative to the config. Each invocation starts fresh and requires a new output directory. `--jobs` defaults to 4; `--cv-replicates` defaults to 8. `--stock-treepl` defaults to `treePL` on PATH. The VGP launchers accept the same options:

```sh
bash dating/treePL/roadies_v1.1.16b/roadies_v1.1.16b.sh --output roadies-results --treepl /path/to/corrected/treePL
bash dating/treePL/astralpro.l6p1/astralpro.l6p1.sh --output astral-results --treepl /path/to/corrected/treePL
```

The optimizer screens algorithms and effort, then searches smoothing from high to low with independent fitted states for each replicate. Three screened optimizers refine each fit. Competitive minima are refined to 0.25 log10 units; flat regions within 1% stop refining. The largest tested smoothing value within 1% of the lowest median CV score is selected. Held-out taxa remain paired across smoothing values. Nonfinite, negative, or extreme CV scores above `1e12` are discarded and retried. Four independent final fits receive tighter refinement; shortlisted stock settings are checked with three fresh seeds each. There are no runtime cutoffs.

Five files are saved: `recommended.config`, `dated.tre`, `input.tre`, `results.tsv`, and the live `summary.png`. Working files are temporary. Run `treePL recommended.config` from the output directory using stock treePL. Rerun the optimizer to reproduce the full workflow.

## Build treePL

The [patch](treepl-fixes.patch) corrects CV sampling, CV optimizer selection, gradient clipping, and annealing acceptance, and adds separate CV seeds and best-fit carryover. Build it separately from any installed treePL:

```sh
curl -L https://github.com/blackrim/treePL/archive/551cbde1a530adad7986c530ca1f254e3ffd42c7.tar.gz -o treePL.tar.gz
tar -xzf treePL.tar.gz
cd treePL-551cbde1a530adad7986c530ca1f254e3ffd42c7
patch -p1 < /absolute/path/to/vgp-dating/dating/treePL/treepl-fixes.patch
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

The version must include `vgp-optimizer-fixes-7`. Use this executable with `--treepl`; no installation step is needed. Rebuild from clean objects after changing the patch.

## Figures and checks

The [overview script](plot_treepl.R) requires `phytools`, `plotrix`, and `png`. From an analysis directory, regenerate its scientific-name tree, calibration-age table, overview, and full-tree PDF; for example:

```sh
Rscript ../plot_treepl.R astralpro.l6p1
Rscript ../plot_dated_tree.R --tree generated/astralpro.l6p1.scientific.treePL.tre --accession-tree generated/astralpro.l6p1.treePL.tre --calibrations generated/astralpro.l6p1.calibrated_node_ages.tsv --output generated/astralpro.l6p1.dated.pdf --title 'ASTRAL treePL'
```

From the repository root, `Rscript dating/treePL/calibration_config.R` checks calibration mappings and bounds; `python3 -m unittest discover -s dating/treePL/tests` checks the optimizer's selection and retry rules.
