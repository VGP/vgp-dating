#!/bin/bash
set -e

# Run from this analysis directory, regardless of the caller's working directory.
cd "$(dirname "$0")"
mkdir -p generated

# Benchmark optimization settings.
../treepl_parameter_benchmark.sh \
  roadies_v1.1.16b_wrapper.config \
  ../../trees/roadies_v1.1.16b.nwk \
  full > generated/benchmark.log 2>&1

# Run with the settings recorded in the final configuration.
treePL roadies_v1.1.16b.config > generated/roadies_v1.1.16b.config.log 2>&1

# Select the lowest-objective result from 200 replicates with random seeds.
../treepl_replicate_select.sh roadies_v1.1.16b.config 200 random > generated/replicates.log 2>&1

# Use the selected replicate for subsequent plotting and age reporting.
cp generated/treepl_replicate_runs/roadies_v1.1.16b.lowest_objective.tre \
  generated/roadies_v1.1.16b.treePL.tre
