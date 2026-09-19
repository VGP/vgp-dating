#!/bin/bash
set -eo pipefail

# Run from this analysis directory, regardless of the caller's working directory.
cd "$(dirname "$0")"
mkdir -p generated
stage=benchmark
printf 'status=running\nstage=%s\n' "$stage" > generated/final_run_status.txt
trap 'run_exit=$?; if [ "$run_exit" -ne 0 ]; then printf "status=failed\nstage=%s\nexit_status=%s\n" "$stage" "$run_exit" > generated/final_run_status.txt; echo "Analysis incomplete: $stage failed (exit $run_exit)." >&2; fi' EXIT

# Benchmark optimization settings.
../treepl_parameter_benchmark.sh \
  roadies_v1.1.16b_wrapper.config \
  ../../trees/roadies_v1.1.16b.nwk \
  full 2>&1 | tee generated/benchmark.log

# Apply the numeric settings and complete prime flag combination.
stage=config_update
python3 - <<'PY'
from pathlib import Path
import re

recommendation = Path('generated/treepl_parameter_benchmark/final_recommendation.txt')
values = dict(line.split('=', 1) for line in recommendation.read_text().splitlines() if '=' in line)
if values.get('status') != 'complete':
    raise SystemExit('Benchmark recommendation is incomplete; stopping.')
config = Path('roadies_v1.1.16b.config')
text = config.read_text()
for key in ('smooth', 'opt', 'optad', 'optcvad', 'pliter', 'plsimaniter'):
    value = values.get(key, '')
    pattern = r'\d+(?:\.\d+)?(?:[eE][+-]?\d+)?' if key == 'smooth' else r'\d+'
    if not re.fullmatch(pattern, value) or (key == 'smooth' and float(value) <= 0):
        raise SystemExit(f'Invalid or missing benchmark setting: {key}')
    text, count = re.subn(rf'(?m)^[ \t]*{key}[ \t]*=[^\n]*$', f'{key} = {value}', text)
    if count != 1:
        raise SystemExit(f'Expected exactly one active {key} setting in the config.')
# Absence in prime output is recorded explicitly as 0, so old flags cannot persist.
for option, flag in (('opt', 'moredetail'), ('optad', 'moredetailad'), ('optcvad', 'moredetailcvad')):
    value = values.get(flag)
    if value not in ('0', '1'):
        raise SystemExit(f'Missing or invalid prime flag: {flag}')
    text = re.sub(rf'(?m)^[ \t]*#?[ \t]*{flag}[ \t]*(?:#.*)?(?:\n|$)', '', text)
    flag_line = flag if value == '1' else '#' + flag
    text, count = re.subn(rf'(?m)^({option}[ \t]*=[^\n]*)(?:\n[ \t]*#[ \t]*)?$',
                          lambda match: match[1] + '\n' + flag_line, text)
    if count != 1:
        raise SystemExit(f'Expected exactly one {option} setting for {flag}.')
temporary = config.with_suffix('.config.tmp')
temporary.write_text(text)
temporary.replace(config)
print('Applied benchmark settings to', config)
PY

# Select the lowest-objective result from 200 replicates with random seeds.
stage=replicates
../treepl_replicate_select.sh roadies_v1.1.16b.config 200 random 2>&1 | tee generated/replicates.log

# Record the selected seed in the final configuration.
stage=seed_update
python3 - <<'PY'
from pathlib import Path
import re

selection = Path('generated/treepl_replicate_runs/selected_replicate.txt')
values = dict(line.split('=', 1) for line in selection.read_text().splitlines() if '=' in line)
seed = values.get('selected_seed', '')
if values.get('status') != 'complete' or not re.fullmatch(r'\d+', seed) or not 1 <= int(seed) <= 2147483646:
    raise SystemExit('Missing or invalid completed replicate selection; stopping.')
config = Path('roadies_v1.1.16b.config')
text, count = re.subn(r'(?m)^[ \t]*seed[ \t]*=[^\n]*$', f'seed = {seed}', config.read_text())
if count != 1:
    raise SystemExit('Expected exactly one active seed setting in the config.')
temporary = config.with_suffix('.config.tmp')
temporary.write_text(text)
temporary.replace(config)
print('Recorded selected seed', seed, 'in', config)
print('Replicate counts:', values['successful'], 'succeeded,', values['failed'], 'failed,', values['attempted'], 'attempted.')
PY

# Save and run the exact final configuration from this analysis directory.
stage=config_snapshot
cp roadies_v1.1.16b.config generated/roadies_v1.1.16b.final.config
printf 'status=running\nstage=final_run\nconfig_updated=yes\n' > generated/final_run_status.txt
echo "Config updated and snapshot saved; final analysis has not yet completed."
stage=final_run
# Remove only the previous final tree so it cannot pass validation after a failed run.
rm -f generated/roadies_v1.1.16b.treePL.tre
treePL generated/roadies_v1.1.16b.final.config 2>&1 | tee generated/roadies_v1.1.16b.config.log

stage=final_validation
Rscript - generated/roadies_v1.1.16b.treePL.tre ../../trees/roadies_v1.1.16b.nwk <<'RS'
suppressPackageStartupMessages(library(ape))
args <- commandArgs(trailingOnly = TRUE)
result <- withCallingHandlers(read.tree(args[1]), warning = function(w) stop(w))
input <- read.tree(args[2])
if (!inherits(result, "phylo") || is.null(result$edge.length) ||
    length(result$edge.length) != nrow(result$edge) ||
    any(!is.finite(result$edge.length)) || any(result$edge.length < 0) ||
    anyDuplicated(result$tip.label) ||
    !identical(sort(result$tip.label), sort(input$tip.label))) {
    stop("Final tree is invalid or does not contain the input tree's taxa.")
}
RS

python3 - <<'PY'
from pathlib import Path
import math

log = Path('generated/roadies_v1.1.16b.config.log').read_text()
objectives = [line.split()[3] for line in log.splitlines()
              if len(line.split()) >= 4 and line.split()[:3] == ['after', 'opt', 'calc:']]
if not objectives or not math.isfinite(float(objectives[-1])):
    raise SystemExit('Final run did not report a finite objective.')
selection = dict(line.split('=', 1) for line in
                 Path('generated/treepl_replicate_runs/selected_replicate.txt').read_text().splitlines())
Path('generated/final_run_status.txt').write_text(
    'status=running\nstage=plotting\nconfig_updated=yes\n'
    'config_snapshot=generated/roadies_v1.1.16b.final.config\n'
    f"final_objective={objectives[-1]}\nselected_replicate_objective={selection['lowest_objective']}\n"
    f"replicates_attempted={selection['attempted']}\nreplicates_successful={selection['successful']}\n"
    f"replicates_failed={selection['failed']}\n")
print('Final tree validated; objective =', objectives[-1])
print('Selected replicate objective =', selection['lowest_objective'])
PY

# Plotting uses paths relative to treePL/, not this analysis directory.
stage=plotting
(
  cd ..
  Rscript roadies_v1.1.16b.treePL.R
) 2>&1 | tee generated/plotting.log

python3 - <<'PY'
from pathlib import Path
status = Path('generated/final_run_status.txt')
status.write_text(status.read_text().replace(
    'status=running\nstage=plotting\n', 'status=complete\nplotting=complete\n', 1))
PY
echo "Analysis completed: final tree validated, plot and age table generated."
