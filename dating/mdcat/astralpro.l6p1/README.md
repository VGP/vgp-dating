# ASTRAL v0.1.1 MD-CAT dating

```bash
python ~/workspace/MD-Cat/md_cat_sample.py -i ~/workspace/vgp-tree-release/v0.1.1/astralpro.l6p1.tre -t astralpro.l6p1.config --strategy independent -o astralpro.l6p1.independent.fastcorrect.tre --jobs 100 --threads 1 --CI "100 0.025 0.975" --max-draws 1000000000 --resume --workdir astralpro.l6p1.independent.fast.tre.runs/
```

The 565-tip ASTRAL-Pro tree was dated with MD-CAT 1.1.15.

| Item | File |
| --- | --- |
| Input tree | [astralpro.l6p1.tre](../../../trees/astralpro.l6p1.tre) |
| Current repository config (91 calibrations) | [astralpro.l6p1.config](../../treePL/astralpro.l6p1/astralpro.l6p1.config) |
| Dated tree (NEXUS) | [astralpro.l6p1.independent.fast95.tre](astralpro.l6p1.independent.fast95.tre) |
| Node-age table (TSV) | [astralpro.l6p1.independent.fast95.tre.tsv](astralpro.l6p1.independent.fast95.tre.tsv) |
| Figure | [PDF](astralpro.l6p1.independent.fast95.pdf) |

The command names the output `fastcorrect`; the available tree and table use `fast95`.

[MD-CAT methods](../README.md) · [Dating overview](../../README.md) · [VGP release v0.1.1](https://github.com/VGP/vgp-tree-release/tree/master/v0.1.1)
