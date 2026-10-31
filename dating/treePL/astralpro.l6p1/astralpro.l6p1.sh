#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$script_dir/../treepl_benchmark.py" "$script_dir/astralpro.l6p1.config" "$@"
