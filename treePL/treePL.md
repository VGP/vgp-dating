# treePL analyses

ASTRAL-Pro l6p1 and ROADIES v1.1.16b use the same end-to-end benchmark. Shared input
trees and annotations live in `../trees/`; topology-specific configurations and
launchers live in their analysis folders. Reproducible outputs remain under
`generated/`.

## Benchmark and launcher

From the repository root, run the ASTRAL launcher (an absolute launcher path also works from any directory):

```sh
bash treePL/astralpro.l6p1/astralpro.l6p1.sh --dry-run
bash treePL/astralpro.l6p1/astralpro.l6p1.sh
```

`treepl_benchmark.py` reads the single analysis config, audits its defining pairs
and ages against the master, validates the input tree, and records input/config,
master, executable, and script fingerprints. Each normal invocation deletes and recreates the analysis `generated/` directory,
then writes results under
`generated/treepl_benchmark/`. The fixed defaults are ten simultaneous PL processes with one thread each,
and five CV processes with two threads each. Defaults are reduced on smaller
machines to stay within the available logical CPU count. There are no
fit timeouts. Progress includes fit starts/completions, completed CV values, and
30-second activity reports with leave-out counts while available. A provisional
current-stage ETA uses observed completion throughput, updating on completions
and every 30 seconds while waiting. It can shift with slower fits and does not
predict unseen stages or enforce a timeout.

The sequence is:

1. At **each smoothing value**, test all 36 `opt`/`optad` pairs with both detail
   flags off, using the first two shared seeds (one if only one was requested).
   Each seed nominates its three lowest-objective valid pairs; exact ties use
   runtime and then pair identifier. Keep the union, at most six pairs.
   Test those survivors across all requested detail combinations and all shared
   seeds, reusing matching nomination evaluations. Select by median objective,
   then worst objective, then runtime. Relative differences within 0.0001%
   (absolute floor 1e-8) are numerical ties for the first two selection criteria.
   All fits use `pliter=50` by default. Voting nominates candidates; full-fit
   performance determines the winner. Failed nomination fits cannot nominate a
   pair, and all failures remain recorded. Matching failed fits are not retried.
2. Run independent **single-value full CV** for each smoothing and every shared
   seed, using that smoothing's selected optimizer configuration. Each job sets
   `cvstart=cvstop`; default `cviter=3`. No descending sweep is needed. After the
   score file closes, verify it against the log and stop the unused post-CV
   full-tree fit; otherwise wait for normal completion.
3. Select the smoothing with the **lowest usable median CV score**. An exact tie
   favors higher smoothing. A boundary minimum or unusable grid point is flagged,
   without automatic expansion or refinement. Raw PL objectives are compared
   only within a smoothing value, never to select smoothing.
4. At the selected smoothing and optimizer configuration, test every shared seed
   at `--final-pliter 200`, both with and without `thorough`. Compare objectives
   and node ages; retain the original screening winner as another eligible fit.
   Repeat the best fit's actual settings in a standalone run. Exact objective ties
   favor higher `pliter`, then no thorough, then smaller seed. Failed extra fits
   are recorded without displacing a valid fit; `final_selection.json` reports
   whether standalone confirmation succeeded. Differences are diagnostics, not
   automatic convergence claims.
5. Publish the optimized config and validated dated tree, and export the plotting
   calibration subset from the same master that was checked. The launcher creates
   scientific-name trees, the existing PNG and calibration age table, and the
   detailed dated-tree PDF. Configs retain commented `#prime` and `#thorough`.

The default grid has 11 values from **1000 through 1e-7**, one per decade.
The default workload is **at most 1,980 optimizer fits, 55 CV jobs, and eleven final fits**.
The shared seeds are 1729, 555136393, 1587025888, 104729, and 130363. A larger
`--seed-count` extends this deterministic list; `--seeds` supplies an explicit list.
The seed setting applies globally to screening, CV, and final comparisons. There is no separate seed
count for any stage; final comparisons reuse the same seed list.

A deliberately coarse outlier screen excludes values **greater than 1000 times
their group's finite median** (configurable with `--outlier-factor`). Screening
groups contain seeds for the same optimizer configuration and smoothing; CV
groups contain seeds for the same smoothing. Raw values are retained; detailed per-fit logs are removed after successful completion unless `--keep-work` is supplied.
The relative filter requires at least three requested seeds and three valid results.
It cannot identify a bad majority or a whole group on a wrong scale. Nonfinite
scores, process failures, and invalid dated trees are failed fits. A group needs
a strict majority of the requested seeds remaining to be eligible. Unusable groups
are skipped; no usable choice stops the analysis. Ordinary seed variation does
not trigger retries or stopping.

Useful options:

- `--seed-count N` or `--seeds 1729,104729,...`.
- `--smoothing-values 1,0.01,0.0001` or `--smoothing-range HIGH LOW COUNT`
  (logarithmically spaced, including both endpoints).
- `--optimizer-pairs 1/3,2/3` and `--details 00,01,10,11` to restrict small tests;
  nomination always uses both flags off, while these options restrict confirmation.
  The two detail digits control `moredetail` and `moredetailad`, respectively.
- `--pliter N`, `--final-pliter N`, `--cviter N`, `--jobs N`, `--threads N`,
  `--cv-jobs N`, and `--cv-threads N`.
- `--thorough` enables thorough in screening and CV. Final comparisons always
  include both modes. The published config comments thorough out; consult the manifest's
  `selected_thorough` when reproducing the selected fit.
- `--master PATH`, `--dry-run`, and `--help`.

For example, inspect a reduced test plan without starting it:

```sh
bash treePL/astralpro.l6p1/astralpro.l6p1.sh --dry-run \
  --seed-count 3 --optimizer-pairs 1/3,2/3 --details 00 \
  --smoothing-range 0.01 0.000001 5
```

### Fixed CPU allocations

Optimizer nomination, confirmation, and final fitting default to **10 jobs × 1
thread**. CV defaults to **5 jobs × 2 threads**. There is no performance-tuning
stage or pilot workload. The small observed CV timing difference between 3×3
and 5×2 did not justify repeating the timing experiment on every run.

Defaults are capped by available logical CPUs (or process affinity where
supported). For example, four CPUs give 4×1 for PL and 2×2 for CV; one CPU gives
1×1 for both. `--jobs` and `--threads` override the corresponding settings for
both stages. `--cv-jobs` and `--cv-threads` take precedence for CV alone. Explicit
allocations may exceed the available CPU count, which emits a warning.

`parallelism.json`, the manifest, and per-fit thread counts record the effective
settings. Each job records its own thread allocation; CV does not change the PL settings.

The pinned treePL implementation's normal CV optimizer uses `optad` and
`moredetailad`; `optcvad`/`moredetailcvad` are preserved but not searched because
they do not control that fitting path. The shared annealing routine uses
`lfsimaniter`; ineffective `plsimaniter`/`cvsimaniter` knobs are not searched.
Other supplied numerical controls remain fixed. `log_pen` is rejected because of
the previously identified objective/gradient mismatch. Multiple CV threads draw
from a shared random generator, so fixed seeds alone do not guarantee identical
results across thread schedules. Negative optimizer return counts are recorded.
This shortlist search can miss pairs that perform poorly with detail flags off
but improve when enabled. It does not guarantee a global optimum.

Re-running deletes **all previous files under the topology's `generated/`**.
Save anything needed elsewhere first. The analysis config is updated only after
selection and validation. There are no resume or retry flags. `--help`, `--dry-run`,
invalid arguments, and failed input preflight preserve existing results.
The launcher holds `.treepl.lock` throughout benchmarking and plotting; direct
Python invocations use the same lock. The launcher forwards interrupts and termination
to its child process group; the benchmark terminates its active treePL process groups. Config, tree, master, and executable fingerprints protect against
changed inputs before publication. Validation checks taxa/topology, finite
nonnegative lengths, ultrametricity, and calibration bounds (tolerance 0.001 Ma).

Under `generated/treepl_benchmark/`, `fits.tsv` records raw fit outcomes;
`assessments.tsv` adds retained/outlier/failed/nomination_only classifications.
Nomination-only fits do not enter the final candidate ranking. Selection is
summarized by `optimizer_nominations.tsv`, `optimizer_shortlists.json`,
`optimizer_summary.tsv`, `optimizer_selections.json`, `cv_scores.tsv`,
`cv_summary.tsv`, `cv_selection.json`, `final_summary.tsv`, and
`final_selection.json`. During a run, per-fit directories retain configs, logs, validation reports and trees.
After successful numerical publication, compact results replace these working files
by default; `--keep-work` disables deletion. `input.config` and `manifest.json` record inputs and provenance.

Four graphics are saved as both PNG and vector PDF: `optimizer_landscape`,
`cv_variation` (raw finite scores, including extremes), `cv_variation_filtered`
(retained replicates), and `final_diagnostics`. They are refreshed after their
respective stages; plot failures warn without stopping numerical analysis. The optimizer
heatmap distinguishes cream cells (not shortlisted) from gray cells (unusable).
The launcher status is `generated/final_run_status.txt`. Plotting logs are separate.
Optional online silhouettes may be omitted on network failure; benchmark graphics
and the detailed dated-tree PDF are offline. `calibration_config.R` remains
available for intentional manual audits.

### Result retention

After publishing the validated dated tree, optimized config and plotting calibration
subset, the benchmark consolidates every evaluation into `evaluations.jsonl`,
including settings, outcomes, failure reasons, assessment, validation reports,
artifact hashes and raw CV score strings. Failed fits retain a short log excerpt. `node_ages.tsv` contains one row per validated full-tree fit,
with a `fit_id` and one column per internal node. CV leave-out trees are not stored.
Existing summary tables, comparison tables, graphics, `input.config`, manifests,
and the main progress log remain. `selected_fit.config` preserves the selected
fit's exact controls, including its actual thorough flag; `selected_validation.log`
preserves its validation report. The published final dated tree remains unchanged.

Only after consolidation succeeds are recorded per-fit directories removed.
`retention.json` records counts and hashes. `--keep-work` retains both compact
results and working files. Runs stopped before publication retain their working
files. Cleanup failures warn and record incomplete retention without invalidating
the published result. An interruption after publication records `published` rather
than a failed analysis. If directory deletion has begun, compact results are already
saved; interruption during consolidation retains working files. The topology-specific plotting steps
run afterward and do not need these intermediate files.

Evaluation records, selections, and summary tables share a relative `fit_id`.
Use it to join `evaluations.jsonl` to `node_ages.tsv`; it identifies a fit even after
its working directory has been removed. The plotter also accepts older tables
with `directory` fields.
Cleanup reduces future output size; it does not change Git's tracked-file status
or remove historical repository contents. It does not clean an already-running
process that loaded an earlier script version.

## ROADIES setup

`roadies_v1.1.16b/` has the same structure as ASTRAL: one analysis config, a launcher,
a topology-specific plotting R script, and recreatable `generated/` outputs.
It retains `numsites=123141`, all 97 calibration pairs and bounds, and its saved
numerical settings. The shared benchmark screens its requested smoothing grid with
`pliter=50` by default, independently of those saved values.

From the repository root:

```sh
bash treePL/roadies_v1.1.16b/roadies_v1.1.16b.sh --dry-run
bash treePL/roadies_v1.1.16b/roadies_v1.1.16b.sh
```

Use `--thorough` to enable it for screening and CV; final comparisons always test both modes. A normal invocation clears only
ROADIES `generated/`; the dry run preserves existing outputs. Both topologies
have separate locks and outputs, but each default run uses up to ten logical CPUs, so run them
sequentially to avoid competing for CPU resources.
The launcher recreates accession and scientific-name dated trees, the PNG,
calibration age table, and dated-tree PDF. The plotting calibration CSV is derived
from the master. The Coraciimorphae 599/600 mapping discrepancy remains unchanged
and visible in the manual node audit; the exact defining pair is used for fitting
and plotting. Setup validation does not establish production completion.

## Calibration audits

`Rscript treePL/calibration_config.R --configs-only astralpro.l6p1` checks the single
ASTRAL config against `calibrations/master_calibrations.csv`. Running the audit
without arguments additionally checks topology node mappings for both trees.
Both topologies use one analysis config; the legacy wrappers have been removed. The documented
ROADIES Coraciimorphae node discrepancy remains an audit item, not a new edit.

## Shared dated-tree visualization

`plot_dated_tree.R` generates a single-page vector PDF with a ladderized time tree, internal node IDs and ages (Ma), translucent gray calibration ranges, and the repository's clade colors. Three diagnostic panels occupy checked open space on the same page: calibration-bound positions, sampled lineages through time, and terminal-branch durations by clade. Tip text uses darker versions of the branch colors for readability. Period bands use the fixed ICS 2024/12 boundaries and official CGMW colors; plotting requires only R and ape, with no network calls.

For the current ROADIES outputs, run from the repository root:

```bash
Rscript treePL/plot_dated_tree.R \
  --tree treePL/roadies_v1.1.16b/generated/roadies_v1.1.16b.scientific.treePL.tre \
  --accession-tree treePL/roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.tre \
  --calibrations calibrations/master_calibrations.csv \
  --output treePL/roadies_v1.1.16b/generated/roadies_v1.1.16b.dated.pdf \
  --title 'ROADIES v1.1.16b'
```

Inputs must be rooted, ultrametric dated trees with present-day tips and branch lengths in Ma. Accessions or scientific names are accepted. A scientific-name tree needs its corresponding accession-labelled tree when calibrations are requested; their tip correspondence, topology, and branch lengths are verified. Exact, unique `AssemblyId` aliases can supply display annotations; they do not replace original tip identifiers when mapping calibration pairs. The calibration table is optional; without one the calibration panel states that no constraints were supplied. `--annotations` overrides the repository annotations. Mammal membership uses the broad `Lineage` field, which includes the separate `VGPLineage=primates` category. Unclassified tips and mixed ancestral branches use charcoal. No source tree or calibration is rewritten.

Constraint ages come only from the supplied master CSV; defining accession pairs are mapped to their MRCAs. Missing or ambiguous identities stop the run rather than trigger substitution. MRCA mapping does not itself validate biological clade compatibility on a new topology: resolve that before supplying its calibrations. The ROADIES CORACIIMORPHAE pair resolves to node 599, as already recorded in the master's notes, rather than placeholder 600. Gray bars are constraints, not estimated-age confidence intervals. Multiple constraints at the same node retain separate audit rows and may have overlapping bars.

Unique integer internal node labels are preserved; otherwise IDs are the input tree's ape node indices. Ladderization preserves those IDs. Other input internal labels, such as support values, are not plotted as node numbers. The PDF is deliberately tall so every tip and node can be read at zoom. `--width` and `--height` override dimensions in inches. Insets are placed only where they avoid branches, calibration ranges, and node labels; small trees reserve extra white space to the left on the same page. If labels or panels cannot fit, the script stops and asks for more space rather than hiding tree elements. The completed PDF replaces an existing output only after rendering succeeds.

Alongside the PDF, `.nodes.tsv` records node IDs and ages, `.calibrations.tsv` records mapped constraints and normalized bound positions, and `.panels.tsv` records panel positions. These are regenerable plotting reports. Calibration positions are `(age - minimum) / (maximum - minimum)`; fixed-age constraints are labelled separately. LTT counts reconstructed sampled lineages immediately younger than each branching event, using a log count axis, and does not infer diversification rates or correct for taxon sampling. Terminal-duration points include every sampled tip; boxes show quartiles and median, with standard 1.5-IQR whiskers. Both launchers call the shared plotter after their topology-specific plotting step has written the scientific-name dated tree. Output is logged to `generated/dated_plotting.log`; a failure reports `stage=dated_plotting`, and successful workflow completion records `dated_pdf=complete`. The existing PNG and age-table outputs are retained. The heading uses `--title` (or the input filename) and computes the tip and calibration counts; explanatory plot captions are omitted. The PDF omits the outside-bounds count; input validation and the calibration audit table retain that check.


## ASTRAL-Pro l6p1

`astralpro.l6p1/` contains one analysis config, the end-to-end launcher, a
topology-specific plotting R script, and recreatable `generated/` outputs.

The user confirmed substitution-unit branch lengths and approved `numsites =
162228`, the total gene-tree count supplied by Siavash. The specific length
estimator was not supplied. The input has 565 tips and is rooted between the
three cyclostomes and the remaining vertebrates.

Approved ASTRAL calibration decisions:

- Omit CAL001–004 (Deuterostomia, Ambulacria, Chordata, Olfactores), CAL033
  (Batrachia), CAL038 (Salamandroidea), and CAL039 (Pleurodelinae): their calibrated
  divergences are absent. In particular, the surviving Batrachia descendants form
  Anura, not Batrachia. The master CSV retains all seven entries for other trees.
- Retain CAL015 with its exact Lampris/Polymixia pair at input-tree ape node 641,
  93.9–145 Ma. Its ASTRAL clade has nine rather than three sampled descendants.
- Retain CAL094 with its exact Colius/Merops pair at node 1077, 62.2–91.9 Ma.
  This is the seven-tip Coraciimorphae clade. The separate ROADIES 599/600 issue
  is unchanged; its pair spans a broader clade there.
- Retain the other 88 calibrations with their exact pairs and bounds. All 90
  retained pairs are present; the audit found no shared-node collisions or
  incompatible ancestor/descendant bounds. The root uses CAL005 at node 566;
  Anura uses CAL034 at node 748.

`master_calibrations.csv` records `node_astralpro_l6p1` alongside the ROADIES
node column. Blank ASTRAL cells identify the seven approved omissions. Node
numbers use input-tree ape indices, not treePL's internal numbering.

The standalone ASTRAL calibration audit performs a lightweight, read-only check
of its single analysis config calibration pairs and min/max ages against the master.
The topology's populated node column determines which calibrations are expected;
the check respects the approved omissions and catches missing, extra, duplicate,
or changed entries. It does not read trees, compare node numbers, or regenerate
configs. A mismatch returns a nonzero exit status for review.

After major updates, intentionally run the broader audit from the repository root:

```sh
Rscript treePL/calibration_config.R
```

This scans both topologies' configs and compares master node numbers to exact-pair
MRCAs. It reports discrepancies without changing files, returning a nonzero exit
status when review is needed. The documented ROADIES CAL094 600/599 discrepancy
remains visible in this manual audit and does not block the lightweight run check.
To invoke the lightweight ASTRAL check manually:

```sh
Rscript treePL/calibration_config.R --configs-only astralpro.l6p1
```

The benchmark exports
`generated/astralpro.l6p1.calibrations.csv` using populated ASTRAL node cells in the
master. That CSV is a derived plotting input, not an independently maintained
calibration source. Display names preserve the
explicit kxProAnne1 annotation alias and distinguish duplicate human/mouse
assemblies by accession suffix. The plotting script produces the same output
kinds as ROADIES, including its existing PNG workflow with online silhouettes.
Completion of the new full ASTRAL workflow must be established by its run manifest and launcher status; setup and small-tree checks are not a production validation.
