# ROADIES v0.0.0 MD-CAT dating

[Dating overview](../../README.md) · [Shared methods and table guide](../README.md) · [VGP release v0.0.0](https://github.com/VGP/vgp-tree-release/tree/master/v0.0.0)

This analysis dates the 581-tip ROADIES reference tree using MD-CAT 1.1.15. The output summarizes 100 fitted runs with mean node ages and 95% pooled-percentile age intervals. Ages and branch lengths are in Ma.

## Inputs and outputs

| Item | File |
| --- | --- |
| Reference input tree | [roadies_v1.1.16b.nwk](../../../trees/roadies_v1.1.16b.nwk) |
| Current repository config (96 calibrations) | [roadies_v1.1.16b.config](../../treePL/roadies_v1.1.16b/roadies_v1.1.16b.config) |
| Annotated NEXUS dated tree | [roadies_v1.1.16b.independent.fast95.tre](roadies_v1.1.16b.independent.fast95.tre) |
| Node-age table | [roadies_v1.1.16b.independent.fast95.tre.tsv](roadies_v1.1.16b.independent.fast95.tre.tsv) |
| Figures | [PDF](roadies_v1.1.16b.independent.fast95.pdf), [overview PNG](roadies_v1.1.16b.independent.fast95.png) |

The config uses the treePL format accepted directly by MD-CAT. See the [config provenance note](../README.md#calibration-configs-and-commands) before treating the current repository copy as the original run snapshot.

## Command supplied by Siavash

```bash
python ~/workspace/MD-Cat/md_cat_sample.py -i ~/workspace/vgp-tree-release/v0.0.0/roadies_v1.1.16b.nwk -t roadies_v1.1.16b.config --strategy independent -o roadies_v1.1.16b.independent.fast95.tre --jobs 100 --threads 1 --CI "100 0.025 0.975" --max-draws 1000000000 1> roadies_v1.1.16b.independent.fast95.log 2> roadies_v1.1.16b.independent.fast95.err
```

These are the original workspace paths. The command expects the config in the working directory and writes its outputs there; the exact working directory has not yet been recorded. Standard output and standard error were redirected to the named `.log` and `.err` files, which are not currently included here.

## Run notes to complete

Siavash can add the original run manifest and config snapshot here, along with the exact software checkout, execution date, and environment. The retained dated tree matches the release's `roadies_v1.1.16b.dated.nexus`; the [shared file guide](../README.md#files-and-release-correspondence) records the verified release revision.
