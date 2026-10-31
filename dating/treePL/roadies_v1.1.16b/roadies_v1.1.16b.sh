#!/bin/bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$script_dir/../treepl_benchmark.py" "$script_dir/roadies_v1.1.16b.config" "$@"
