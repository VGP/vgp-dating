#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Benchmark, confirm and publish the best tree/config, then create dated-tree plots.
# The Python entry point holds the analysis lock and handles worker shutdown.
exec python3 ../treepl_benchmark.py astralpro.l6p1.config "$@"
