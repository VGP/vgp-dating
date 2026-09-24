# treePL analyses

`treepl_benchmark.py` is an independent four-stage benchmark: **replicated randomCV**, an
**exhaustive optimizer screen at the selected smoothing**, a **deep seed search
over a capped configuration list**, and **standalone confirmation, publication,
and plotting**. Both launchers run all stages in order. Numerical inputs and
calibration decisions remain fixed; the final stage updates the saved numerical
settings and publishes the selected dated tree.

## Run the benchmark

From the repository root (absolute launcher paths also work):

```sh
bash treePL/astralpro.l6p1/astralpro.l6p1.sh --dry-run
bash treePL/astralpro.l6p1/astralpro.l6p1.sh
# Same modules, ROADIES inputs:
bash treePL/roadies_v1.1.16b/roadies_v1.1.16b.sh
```

Python 3, treePL, R, and the R packages `ape`, `rphylopic`, `phytools`, `plotrix`, and `png` are required.
Plotting dependencies, script availability, annotation columns and tip mappings,
scientific names, and the readable VGP logo are checked before fitting. Validation and plotting
helpers are embedded in the Python module; no retired benchmark or diagnostic
code is imported. `RandomCV.run()` returns the smoothing selection consumed by
`OptimizerScreen.run()`, which supplies candidates to `DeepSeedSearch.run()`.
An incomplete CV run does not start the second module; an optimizer screen with
no eligible configuration does not start the third. `FinalPublication.run()`
confirms and publishes the best retained validated fit, then runs the plotting scripts.

### Config check and inputs

Before fitting or replacing prior module output, check the config's exact defining
accession pairs and ages against `calibrations/master_calibrations.csv`. Populated
topology node cells select the expected calibrations, preserving approved omissions.
Check the rooted input tree, unique taxa, finite nonnegative lengths, defining-taxon
presence, positive integer `numsites`, and feasible calibration bounds on the tree.
This is not the broader manual node-number audit described below.

Each topology retains its scientific inputs: ASTRAL has 565 tips, 90 calibrations,
and `numsites=162228`; ROADIES has 581 tips, 97 calibrations, and `numsites=123141`.
Input config, tree, master, and executable hashes are recorded. Fits use snapshots;
source inputs are checked again before reporting the final selection.

### Sampling and selection

Defaults:

- **15 smoothing values**, one per decade from **1e4 to 1e-10**.
- **64 accepted randomCV seeds per value**: continuously replenished workers; rejected attempts are replaced.
- **8 concurrent jobs × 2 threads** per job, for both screening and CV.
- `pliter=50`, `cviter=3`, thorough off throughout this module.

At each smoothing value:

1. Compare three `(opt, optad, moredetail, moredetailad)` configurations:
   `(1,3,0,0)`, `(2,3,1,1)`, and `(2,3,0,0)`. Use **three shared seeds**,
   nine full-tree fits total, validating each output tree. A candidate must complete
   every requested screening seed. Rank by median objective, then worst objective,
   then runtime and candidate identifier. The first two criteria treat differences
   within 0.0001% (absolute floor 1e-8) as numerical ties. This short screen chooses
   a strategy for CV; it is not the final exhaustive optimizer search.
2. Use that candidate for independent one-value randomCV runs (`cvstart=cvstop`).
   Generate and record fresh seeds deterministically from `--seed`; replace rejected
   or failed attempts until the requested accepted count is reached. Refill freed
   worker slots without waiting for slower attempts. Accepted scores plus in-flight
   attempts never exceed the requested count; replacements launch before progress
   plotting. No full CV is run.
3. Select the **lowest observed median accepted CV score**, breaking exact ties
   toward higher smoothing. Notch overlap does not influence selection. Flag a
   boundary winner without expanding the grid.

Notches use median +/- 1.58 IQR/sqrt(n), with Tukey hinges matching R's
[boxplot statistics](https://www.stat.ethz.ch/R-manual/R-devel/RHOME/library/grDevices/html/boxplot.stats.html).
Notches are visual diagnostics only, not a selection test.
The CV panel shows notched boxes and individual scores on a logarithmic score
axis, connected medians, and the selected smoothing in gold. Notches are omitted
visually if they extend outside the box hinges or there are fewer than five scores;
the full limits remain in the comparison table. Calculations
use the original score scale. No additional fitting or resampling is required.

The installed treePL implementation uses ten random groups of 10% of tips.
`randomcviter` and `randomcvsamp` are not effective controls in that build and are
not emitted. Its randomCV scores have different normalization from full CV.
`optcvad` and `moredetailcvad` remain inherited config settings; the normal CV fitting
path uses `optad` and `moredetailad`. Other numerical settings are held fixed.
`log_pen` remains unsupported because of the identified objective/gradient mismatch.

Two threads can interleave their stdout, so group progress is approximate. Only
unambiguous numeric partial-score lines are used for early rejection. Completion
requires one final score at the requested smoothing, agreement with the saved CV
score file, and the random-subsampling mode. The unused post-CV full-tree fit is
stopped. Thread scheduling can change random draws despite recorded seeds.

### Coarse failure screen

Reject nonfinite, negative, or extremely large scores. The initial ceiling is
`1e12`; after at least three accepted scores, use **100 times their same-value
median**. Completed scores are reassessed whenever attempts finish. In-flight fits retain
the threshold assigned at launch; their completed scores are then reassessed. This deliberately
loose heuristic permits ordinary variation; it cannot detect a bad majority or
prove that an accepted run is numerically optimal. Replacement conditions the
sample on acceptance, so rejection counts and all attempt records remain visible.

There are no fit timeouts or consecutive-failure cutoffs. Rejected or failed CV
attempts are replaced until each value reaches the requested accepted count;
manual interruption remains available. Filesystem and process-launch errors stop
with an error rather than being retried as bad seeds. A value with no valid optimizer candidate
is incomplete.
Only values with the full requested accepted count are eligible for selection;
if any value is incomplete, the overall run returns a nonzero status and its
best available selection is explicitly provisional.

### Controls

```sh
# Inspect a reduced plan without running fits or replacing outputs:
bash treePL/astralpro.l6p1/astralpro.l6p1.sh --dry-run \
  --smoothing-values 1,1e-4,1e-5 --seed-count 4 --screen-seeds 1

# Define a denser logarithmic grid explicitly:
bash treePL/astralpro.l6p1/astralpro.l6p1.sh \
  --smoothing-range 0.001 0.000001 7 --seed-count 64 --jobs 8 --threads 2
```

`--seed-count` controls accepted CV replicates; `--screen-seeds` separately controls
only the inexpensive optimizer check. Other options are `--seed`, `--pliter`,
`--cviter`, `--fallback-ceiling`, `--outlier-factor`, `--master`,
`--output`, `--keep-work`, and `--help`. Post-CV controls are described below.
CPU allocation is explicit: 8×2 requests
16 threads, even on this 10-logical-CPU Mac. A message reports oversubscription;
use fewer jobs if desired. Run topologies sequentially to avoid competing workloads.

### Outputs and lifecycle

Outputs live in the topology's **`generated/randomcv/`**. A normal rerun replaces
only this benchmark's prior output, after successful preflight. It never clears other
`generated/` contents. An unrelated output directory is not deleted. `--dry-run`
checks the actual inputs without creating run output. A topology lock prevents
concurrent analyses, and interruption stops worker process groups.

- `cv_attempts.tsv` and `optimizer_fits.tsv`: every completed attempt, updated as
  jobs finish, with settings, seed, runtime, outcome, and rejection reason.
- `cv_comparison.tsv`: quartiles, notch limits, and the selected minimum.
- `cv_summary.tsv`, `optimizer_summary.tsv`, and `selection.json`: medians,
  selected candidates, completeness, and the selected smoothing.
- `progress.png` and vector `progress.pdf`: accepted CV variation and medians,
  rejection counts, within-value optimizer comparisons, and runtimes. These refresh
  after each screen and as CV attempts finish; axes adapt to the requested grid.
- `progress.log`: starts, completions, 30-second activity reports, accepted counts,
  and a provisional ETA based on observed throughput, including replacement costs.
- Input snapshots, `manifest.json`, and a copy of the script record provenance.
- `evaluations.jsonl` consolidates all completed evaluation settings, outcomes,
  validation reports, raw scores, and failure log excerpts. Per-fit work is removed
  after consolidation unless `--keep-work` is supplied. Interrupted runs retain work.

## Module 2: exhaustive optimizer screen

After complete CV, hold its selected smoothing fixed and compare **144 optimizer
configurations × three shared seeds = 432 full-tree fits**. This evaluates
`opt=0..5`, `optad=0..5`, and all four combinations of `moredetail` and
`moredetailad`. All fits use **`pliter=200`, thorough off**, and the same jobs and
threads as module 1. No additional CV is performed.

The three screening seeds are shared across all 144 configurations. Their
recorded deterministic generator is separate from CV replacement sampling, so
extra failed CV attempts do not change the screening seed list.

A configuration is eligible only when every requested seed returns a validated
dated tree and finite nonnegative objective. Rank by **median**, then **worst**,
then **best** objective, followed by runtime and identifier for exact ties.
Select the deep-search candidates directly using the rules below; retain all 144
configuration summaries. Rankings do not prove global optimality or age convergence.
Failed fits remain visible; if no candidate is eligible, the module is incomplete
and the launcher returns a nonzero status.

Controls: `--optimizer-seeds` (3) and `--optimizer-pliter` (200).
These are independent of `--screen-seeds` and `--pliter`,
which still control the short pre-CV checks. Smaller budgets can be used for
manual smoke tests without changing defaults.

Outputs are in `generated/randomcv/optimizer_screen/`:

- `fits.tsv` updates after completed fits; `summary.tsv` records every candidate's
  completed/valid/failed count, objective summaries, runtime, rank, and deep-selection status.
- `selection.json` records the selected deep-search configurations and selection rule;
  `manifest.json` records smoothing, seeds, budget, completion, and parallelism.
- `optimizer_screen.png` and vector PDF show four 6×6 optimizer grids, one for
  each detail-flag combination. Cells show median-objective percentage gaps,
  deep-search selection, and pending/unusable configurations. Reports refresh
  about every 30 seconds during fitting and at completion.
- `evaluations.jsonl` retains each fit's controls, objective, validation, failure
  diagnostics, and validated Newick tree for later node-age comparisons. Working
  files are removed after consolidation unless `--keep-work` is requested.

Progress and a provisional stage ETA are appended to the main `progress.log`.
The root manifest describes the whole run; the original `selection.json` remains
specifically the CV decision. All optimizer rankings remain available even when the deep-search candidate list is capped.

## Module 3: deep seed search

At the selected smoothing, use **50 shared seeds per configuration**,
**`pliter=2500`**, thorough off. Cap the default configuration list at **two**,
for at most **100 deep fits**, using the same jobs and threads as earlier stages.

Trim the optimizer results as follows:

1. Keep the eligible configuration ranked first by median/worst/best objective.
2. Add the eligible configuration with the lowest individual objective, if
   different. This may differ from the next configuration in median rank.
3. Fill any remaining slot with the next-ranked eligible configuration. No extra
   configuration is added solely for optimizer-family diversity.

The full 144-configuration screen remains saved. `optimizer_screen/selection.json`
records `deep_candidates` and each inclusion reason. The cap is strict: ties do
not increase the deep workload. Fewer candidates are used if fewer qualify.

A separate recorded generator makes 50 fresh seeds by default, excluding optimizer-screen
seeds; exactly the same list is used for every retained configuration. Jobs are
interleaved by seed and configuration. Complete the entire attempted seed budget
without early stopping or replacing failed seeds. Failures remain recorded; they
do not qualify as best fits. Carry forward the best validated full-tree fit from
both earlier screens at the selected smoothing. Retain the lowest valid objective
across that earlier winner and the deep fits, breaking
exact printed-objective ties by candidate identifier and then seed. This tie rule
is deterministic, not evidence that tied fits have identical ages.

Controls: `--deep-seeds` (50), `--deep-pliter` (2500), and
`--deep-configurations` (2). Smaller values allow manual pipeline tests.

`generated/randomcv/deep_seed_search/` contains:

- `fits.tsv`, per-configuration `summary.tsv`, and the recorded settings/seeds in
  `manifest.json`; the main progress log reports completions, failures, and ETA.
- `age_comparison.tsv`: each valid fit's objective gap and median/maximum node-age
  difference from the best retained fit. The earlier winner appears at seed index
  zero. Nodes map to the authoritative input-tree
  clades. All fits are reported, so near-best fits can be compared without imposing
  an arbitrary age-stability acceptance threshold.
- `deep_search.png` and PDF: best objective found as shared seeds accumulate, and
  objective gaps versus maximum node-age differences. These refresh about every
  30 seconds when valid results exist, and at completion. Partial curves include
  only finished fits and do not implement a stopping rule.
- `selection.json`, `best.json`, `best.tre`, `best_node_ages.tsv`, and
  `best.config`: the best result across earlier screening and deep searching. Its config uses the saved input tree
  and a separate `best_standalone.tre` output for manual reproduction; the final module records its own confirmation separately.
- `earlier_best.json`, tree/config, mapped ages, and validation log preserve the
  best earlier screening fit at the selected smoothing.
- `evaluations.jsonl`: compact settings, outcomes, validated Newick trees, and
  input-node age vectors for every valid fit. Work files are removed after
  consolidation unless `--keep-work` is requested.

Completion means the requested deep attempts finished and the best validated
fit was retained, including the earlier winner if no deep fit improves it. It does not
claim a global optimum or consistent ages. These deep-search outputs are provisional until the final stage below confirms and publishes the selected result.

Smoothing values in fit and final configs use up to 12 significant digits, with
compact exponents (for example, `1e-7`). Custom grids retain numerical precision
without long floating-point artifacts.

## Module 4: final confirmation, publication, and plotting

Repeat the best retained fit **once**, using exactly its smoothing, optimizer
configuration, seed, `pliter`, thread count, and thorough off. Validate its output
and compare its objective and input-mapped node ages with the saved winner.
This is a confirmation run, not another parameter search.

Publish the confirmation tree only if it is valid and has a **strictly lower
printed objective**. On an equal objective, a worse objective, or a failed
confirmation, retain the independently revalidated retained winner. Record
both objectives, median/maximum age differences when available, confirmation
status, and the source of the selected tree. Threaded reproduction need not be
identical; a failed or differing rerun is reported rather than silently erased.

Before publication, check source input and executable hashes again and validate
the selected tree and its calibration bounds. Update the topology config with
the selected smoothing, optimizer/detail settings, seed, `pliter`, and thread
count in place, preserving section order and comments; retain commented
`#prime` and `#thorough`. Publish the accession tree to
`generated/TOPOLOGY.treePL.tre` and export the topology's calibration subset from
the checked master to `generated/TOPOLOGY.calibrations.csv`. The original config,
any previous output tree, and any previous subset are backed up under
`generated/randomcv/final/before_publication/`. Handled publication-write failures
roll back replaced files; the run manifest records progress between stages.

The analysis lock remains held while the existing topology R script creates the
scientific-name dated tree, arc PNG, and calibration-age table. Then
`plot_dated_tree.R` creates the detailed dated-tree PDF. Its three diagnostic
panels and shared clade-color legend occupy one aligned, collision-checked block.
Optional online silhouettes retain their existing nonfatal handling.

`generated/randomcv/final/` records the confirmation, exact published config,
selected tree and node ages, validation report, selected source, and publication
hashes. `generated/final_run_status.txt` and the manifests report completion or the
failed stage. A plotting failure returns a nonzero status but **keeps the published
validated numerical result**, with status `published_plot_failed`; it does not
claim successful graphics. `tree_plotting.log` and `dated_plotting.log` remain in
`generated/`. Only successful publication plus all requested plots marks the full
workflow complete.

Superseded benchmarks and temporary diagnostics were removed from the repository
and retained for reference at `/private/tmp/vgp-treepl-reference-20260922-135405`.
That is a temporary reference archive, not a dependency or permanent results store.

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

Inputs must be rooted dated trees, ultrametric within the pipeline tolerance of 0.001 Ma, with present-day tips and branch lengths in Ma. Accessions or scientific names are accepted. A scientific-name tree needs its corresponding accession-labelled tree when calibrations are requested; their tip correspondence, topology, and branch lengths are verified. Exact, unique `AssemblyId` aliases can supply display annotations; they do not replace original tip identifiers when mapping calibration pairs. The calibration table is optional; without one the calibration panel states that no constraints were supplied. `--annotations` overrides the repository annotations. Mammal membership uses the broad `Lineage` field, which includes the separate `VGPLineage=primates` category. Unclassified tips and mixed ancestral branches use charcoal. No source tree or calibration is rewritten.

Constraint ages come only from the supplied master CSV; defining accession pairs are mapped to their MRCAs. Missing or ambiguous identities stop the run rather than trigger substitution. MRCA mapping does not itself validate biological clade compatibility on a new topology: resolve that before supplying its calibrations. The ROADIES CORACIIMORPHAE pair resolves to node 599, as already recorded in the master's notes, rather than placeholder 600. Gray bars are constraints, not estimated-age confidence intervals. Multiple constraints at the same node retain separate audit rows and may have overlapping bars.

Unique integer internal node labels are preserved; otherwise IDs are the input tree's ape node indices. Ladderization preserves those IDs. Other input internal labels, such as support values, are not plotted as node numbers. The PDF is deliberately tall so every tip and node can be read at zoom. `--width` and `--height` override dimensions in inches. The three diagnostic panels and clade-color legend share one aligned vertical block, placed only where it avoids branches, calibration ranges, and node labels. Small trees reserve extra white space to the left on the same page; default page height also accommodates the full panel block. If labels or panels cannot fit, the script stops and asks for more space rather than hiding tree elements. The completed PDF replaces an existing output only after rendering succeeds.

Alongside the PDF, `.nodes.tsv` records node IDs and ages, `.calibrations.tsv` records mapped constraints and normalized bound positions, and `.panels.tsv` records panel positions. These are regenerable plotting reports. Calibration positions are `(age - minimum) / (maximum - minimum)`; fixed-age constraints are labelled separately. LTT counts reconstructed sampled lineages immediately younger than each branching event, using a log count axis, and does not infer diversification rates or correct for taxon sampling. Terminal-duration points include every sampled tip; boxes show quartiles and median, with standard 1.5-IQR whiskers. The final pipeline stage runs the topology-specific R script first, then this shared plotter, while holding the analysis lock. The heading uses `--title` (or the input filename) and computes the tip and calibration counts; explanatory plot captions are omitted. The PDF omits the outside-bounds count; input validation and the calibration audit table retain that check.


## ASTRAL-Pro l6p1

`astralpro.l6p1/` contains one analysis config, the module launcher, a
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

The final module exports
`generated/astralpro.l6p1.calibrations.csv` using populated ASTRAL node cells in the
master. That CSV is a derived plotting input, not an independently maintained
calibration source. Display names preserve the
explicit kxProAnne1 annotation alias and distinguish duplicate human/mouse
assemblies by accession suffix. The plotting script produces the same output
kinds as ROADIES, including its existing PNG workflow with online silhouettes.
A completed full run is identified by the final manifest and `generated/final_run_status.txt`, including successful dated-tree plotting.
