# treePL testing ground

This folder is just for running tests using [treePL](https://github.com/blackrim/treePL) to see how the tree responds to different constraints. Here is an example with the current [constraints](/calibrations/calibrations.md):

![treePL constraints test](roadies_v1.1.16b/generated/roadies_v1.1.16b.treePL.png)

Shared input trees and annotations are stored in `../trees/`. Configurations and results for each analysis are kept in its own folder, currently `roadies_v1.1.16b/`. All analysis outputs are kept in `generated/` beneath the configuration directory, including benchmark and replicate results, logs, dated trees, plots, and age reports. Configurations and the launcher stay outside this folder. The launcher recreates `generated/` when needed; it does not delete existing results automatically.

Run the ROADIES launcher with `bash treePL/roadies_v1.1.16b/roadies_v1.1.16b.sh` from the repository root. It benchmarks settings, runs the final configuration as written, then selects the lowest-objective tree from 200 replicates with random seeds and copies it to the standard result filename for plotting. It does not automatically transfer benchmark recommendations. Run the plotting script from `treePL/` with `Rscript roadies_v1.1.16b.treePL.R`. Existing results have been moved without rerunning the analysis.
