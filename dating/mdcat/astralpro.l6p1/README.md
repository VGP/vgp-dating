# ASTRAL v0.1.1 MD-CAT dating

[Dating overview](../../README.md) · [Shared methods and table guide](../README.md) · [VGP release v0.1.1](https://github.com/VGP/vgp-tree-release/tree/master/v0.1.1)

This analysis dates the 565-tip ASTRAL-Pro reference tree, including `kxProAnne1` (lungfish), using MD-CAT 1.1.15. The output summarizes 100 fitted runs with mean node ages and 95% pooled-percentile age intervals. Ages and branch lengths are in Ma.

## Inputs and outputs

| Item | File |
| --- | --- |
| Reference input tree | [astralpro.l6p1.tre](../../../trees/astralpro.l6p1.tre) |
| Current repository config (91 calibrations) | [astralpro.l6p1.config](../../treePL/astralpro.l6p1/astralpro.l6p1.config) |
| Annotated NEXUS dated tree | [astralpro.l6p1.independent.fast95.tre](astralpro.l6p1.independent.fast95.tre) |
| Node-age table | [astralpro.l6p1.independent.fast95.tre.tsv](astralpro.l6p1.independent.fast95.tre.tsv) |
| Figure | [PDF](astralpro.l6p1.independent.fast95.pdf) |

The config uses the treePL format accepted directly by MD-CAT. See the [config provenance note](../README.md#calibration-configs-and-commands) before treating the current repository copy as the original run snapshot.

## Command supplied by Siavash

```bash
python ~/workspace/MD-Cat/md_cat_sample.py -i ~/workspace/vgp-tree-release/v0.1.1/astralpro.l6p1.tre -t astralpro.l6p1.config --strategy independent -o astralpro.l6p1.independent.fastcorrect.tre --jobs 100 --threads 1 --CI "100 0.025 0.975" --max-draws 1000000000 --resume --workdir astralpro.l6p1.independent.fast.tre.runs/
```

These are the original workspace paths. The command expects the config and saved run directory relative to its working directory, whose exact location has not yet been recorded. It resumes an existing analysis, so the saved manifest and preceding run are needed to reconstruct the full execution history.

## Run notes to complete

Siavash can add the original manifest and config snapshot here, along with the initial command, software checkout, execution date, and environment. The command names its output `astralpro.l6p1.independent.fastcorrect.tre`, while the retained tree and supplied table use `fast95`. The retained tree matches the release's `astralpro.l6p1.dated.nexus`; confirmation of the `fastcorrect` to `fast95` filename history remains to be added. The [shared file guide](../README.md#files-and-release-correspondence) records the verified release revision.
