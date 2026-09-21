#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
script_path="$PWD/$(basename "$0")"
config=astralpro.l6p1.config
# Benchmark options are passed through unchanged; --help describes all options.
dry_run=false
for arg in "$@"; do
  case "$arg" in
    --help|-h) exec python3 ../treepl_benchmark.py "$config" "$@" ;;
    --dry-run) dry_run=true ;;
  esac
done
# Hold a kernel lock across cleanup, benchmarking, and plotting. It releases on exit.
if [ -z "${VGP_TREEPL_LOCK_FD:-}" ]; then
  exec python3 - "$script_path" "$@" <<'PYLOCK'
import fcntl, os, pathlib, signal, subprocess, sys
script = pathlib.Path(sys.argv[1]).resolve()
with (script.parent/'.treepl.lock').open('w') as lock:
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        sys.exit('Another ASTRAL run is active; its outputs were not deleted.')
    env = dict(os.environ, VGP_TREEPL_LOCK_FD=str(lock.fileno()))
    child = subprocess.Popen(['/bin/bash', str(script), *sys.argv[2:]],
                             env=env, pass_fds=(lock.fileno(),), start_new_session=True)
    def forward(signum, frame):
        try:
            os.killpg(child.pid, signum)
        except ProcessLookupError:
            pass
    signal.signal(signal.SIGTERM, forward)
    signal.signal(signal.SIGINT, forward)
    code = child.wait()
    sys.exit(code)
PYLOCK
fi
# The benchmark audits this config against the master before deleting old outputs.
Rscript -e 'p<-c("ape","rphylopic","phytools","plotrix","png"); missing<-p[!vapply(p,requireNamespace,logical(1),quietly=TRUE)]; if(length(missing)) stop("Missing R packages: ",paste(missing,collapse=", "))'
if [ "$dry_run" = true ]; then
  exec python3 ../treepl_benchmark.py "$config" "$@"
fi
status_file=generated/final_run_status.txt
stage=benchmark
set_status() {
  printf 'status=%s\nstage=%s\nconfig=%s\n' "$1" "$stage" "$config" > "$status_file.tmp"
  mv "$status_file.tmp" "$status_file"
}
# The benchmark clears generated/ after preflight and records its own console log.
python3 ../treepl_benchmark.py "$config" "$@"
trap 'code=$?; if [ "$code" -ne 0 ]; then if [ -d generated ]; then set_status failed; fi; echo "ASTRAL workflow stopped at $stage (exit $code)." >&2; fi' EXIT
stage=calibration_plot_input
set_status running
# The benchmark exports this subset from the same master it validated.
test -s generated/astralpro.l6p1.calibrations.csv
stage=tree_plotting
set_status running
Rscript astralpro.l6p1.treePL.R 2>&1 | tee generated/tree_plotting.log
stage=dated_plotting
set_status running
Rscript ../plot_dated_tree.R \
  --tree generated/astralpro.l6p1.scientific.treePL.tre \
  --accession-tree generated/astralpro.l6p1.treePL.tre \
  --calibrations generated/astralpro.l6p1.calibrations.csv \
  --output generated/astralpro.l6p1.dated.pdf \
  --title 'ASTRAL-Pro l6p1' 2>&1 | tee generated/dated_plotting.log
stage=complete
set_status complete
printf 'dated_pdf=complete\n' >> "$status_file"
echo 'ASTRAL benchmark, dated trees, PNG, calibration ages, and dated-tree PDF complete.'
