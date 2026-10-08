# ROADIES v0.0.0 MD-CAT dating

```bash
python ~/workspace/MD-Cat/md_cat_sample.py -i ~/workspace/vgp-tree-release/v0.0.0/roadies_v1.1.16b.nwk -t roadies_v1.1.16b.config --strategy independent -o roadies_v1.1.16b.independent.fast95.tre --jobs 100 --threads 1 --CI "100 0.025 0.975" --max-draws 1000000000 1> roadies_v1.1.16b.independent.fast95.log 2> roadies_v1.1.16b.independent.fast95.err
```

The 581-tip ROADIES tree was dated with MD-CAT 1.1.15.

| Item | File |
| --- | --- |
| Input tree | [roadies_v1.1.16b.nwk](../../../trees/roadies_v1.1.16b.nwk) |
| Current repository config (96 calibrations) | [roadies_v1.1.16b.config](../../treePL/roadies_v1.1.16b/roadies_v1.1.16b.config) |
| Dated tree (NEXUS) | [roadies_v1.1.16b.independent.fast95.tre](roadies_v1.1.16b.independent.fast95.tre) |
| Node-age table (TSV) | [roadies_v1.1.16b.independent.fast95.tre.tsv](roadies_v1.1.16b.independent.fast95.tre.tsv) |
| Figures | [PDF](roadies_v1.1.16b.independent.fast95.pdf), [PNG](roadies_v1.1.16b.independent.fast95.png) |

[MD-CAT methods](../README.md) · [Dating overview](../../README.md) · [VGP release v0.0.0](https://github.com/VGP/vgp-tree-release/tree/master/v0.0.0)
