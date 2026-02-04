# Amphibia calibrations

There are relatively few amphibians sampled in our tree, and relatively few amphibian fossils that have been robustly estimated in total-evidence analyses. Consequently, we rely primarily on a few well-constrained fossil taxa that appear to share robustly diagnostic synapomorphies with major crown groups. Reassuringly, molecular divergence-time estimates for lissamphibians have been relatively consistent across most recent studies, such that variability in estimated ages is not a major area of uncertainty for this group. In particular, we refer to the results of [Feng et al. (2017)](https://www.pnas.org/doi/abs/10.1073/pnas.1704632114) for frogs, [Hime et al. (2021)](https://academic.oup.com/sysbio/article/70/1/49/5828236) for all amphibians, and [Stewart and Wiens (2025)](https://www.sciencedirect.com/science/article/pii/S1055790324002641) for salamanders as the most recent comprehensive studies with detailed discussion of fossil calibrations and age estimates. 

### Calibrations:


**Node 948:** Lissamphibia | 274.4–358.9Ma
**Node calibrated:** Last common ancestor of the clade encompassing caecilians (Gymnophiona), frogs (Anura), and salamanders (Urodela).
**Fossil taxon:** _Gerobatrachus hottoni_ (USNM 489135)
**Minimum age:** 274.4Ma
**Minimum justification:** From the Leonardian (~270–280Ma) of the early Permian, from locality number USNM 40971, the ‘Don's Dump Fish Quarry’ in the Clear Fork Group from Baylor County, Texas, USGS Soap Creek 7.5' quad (Anderson et al. 2008). The age of this formation is roughly contemporaneous with the Kungurian (274.4–283.3Ma; Lucas et al. 2022). Gerobatrachus exhibits a number of features suggesting that it is a stem batrachian (Anderson et al. 2008), while other recent analyses suggest it is a stem lissamphibian and caution its use to calibrate crown Lissamphibia (Kligman et al. 2023). However, much of this uncertainty relates to a separate debate over the fossil ancestors of Lisssamphibia (Lepospondyli or Temnospondyli), which does not necessarily affect the constraint of the extant lineages. Either way, essentially all recent estimates for Lissamphibia predate this taxon, including those that did not use it as a calibration. Consequently, we follow Anderson et al. (2008) in treating it as a stem batrachian, providing a credible minimum bound for the age of Lissamphibia.
Maximum age: 358.9Ma.
Maximum justification: In contrast, we remain more agnostic regarding the maximum bound. Molecular estimates range from the early Permian to the late Devonian (270.9–367.0Ma; Kligman et al. 2023). We place a tentative maximum age of 358.9Ma corresponding to the Devonian–Carboniferous boundary.
Discussion: Anderson et al. (2008) suggested a minimum age of 328–335Ma for the age of crown Lissamphibia based on the earliest appearance of lepospondyls and temnospondyls together. However, recent molecular estimates such as Feng et al. (2017), Hime et al. (2021), and Stewart and Wiens (2025) – potentially misreading Anderson (2008) – confusingly placed a maximum age of 337Ma on this node. Kligman et al. (2023) – despite disagreeing with Anderson et al. (2008) regarding the fossil ancestors of Lissamphibia – nevertheless concur in supporting a Mississippian origin (323.4–358.9Ma) of Lissamphibia. We take a more conservative approach in setting a minimum age based on the oldest putative stem batrachian Gerobatrachus, with a maximum that modestly predates the middle-Carboniferous consensus age of the Mississippian (Kligman et al. 2023). This range encompasses essentially all previous molecular divergence-time estimates, regardless of calibration strategy.


**950:** Anura. For a Type IV calibration, the total-evidence analysis of [Chen et al. 2016](https://www.nature.com/articles/srep19209) estimated _Eodiscoglossus santonjae_ in the crown of Anura, corroborated by the morphological re-description by [Baez and Gomez 2016](https://ri.conicet.gov.ar/handle/11336/60180) and re-analysis by [Gao and Chen 2017](https://bioone.org/journals/American-Museum-Novitates/volume-2017/issue-3876/3876.1/A-New-Crown-Group-Frog-Amphibia--Anura-from-the/10.1206/3876.1.short). This taxon dates to the Barremian, ~121.4–125.8Ma. Other putative crown-group anurans are known from similar ages as summarized in [Gomez and Andres 2019](https://www.sciencedirect.com/science/article/pii/S1631068319301320), but these are not as well-documented. Consequently, we place a minimum bound of 121.4Ma on the MRCA of Anura, with a maximum of 252Ma for the maximum age of the Triassic. This is not particularly close to most existing times, which generally date to the Triassic.

**970:** Dorsipares. For a Type III calibration, a more ancient constraint supported by a few recent studies is _Rhadinosteus parvus_ from the Kimmeridgian of the late Jurassic (150.8-155.7Ma), which forms the sister lineage of _Rhinophrynus_ (Rhinophrynidae) in the time-scaled morphological parsimony analysis of [Agnolin et al. 2020](https://www.sciencedirect.com/science/article/pii/S0895981120301462) and the supertree analysis of [Perez-Ben et al. 2024](https://www.cambridge.org/core/journals/paleobiology/article/frog-limbs-in-deep-time-is-jumping-locomotion-at-the-roots-of-the-anuran-bauplan/AC8EC495E05D51667CAAE5B18FAD1E67). As a result, we place a minimum of 150.8Ma on the MRCA of _Rhinophrynus_ and _Xenopus_ (Dorsipares _sensu_ [Dubois et al. 2021](https://www.mapress.com/mt/article/view/38637)), with a maximum of 252.0 for the maximum age of the Triassic. **This constraint could also be treated as a stem dorsiparid and placed on the MRCA of Geobatrachia.**


### Likelihood checkpoints:

There are well-documented times for likelihood checkpoints at the base of Amphibia. Previous estimates for Lissamphibia (Gymnophiona + Batrachia) with and without _Gerobatrachus_ (depending on its placement as a stem batrachian) were previously compiled by [Kligman et al. (2023)](https://www.nature.com/articles/s41586-022-05646-5). We summarize those here to obtain a 95% CI from the quantiles. Those authors also summarized the published evidence for Batrachia (Salientia + Urodela) and Gymnophiona (Rhinatrematidae + Stegokrotaphia*), which we analyzed in the same manner:

**948:** Lissamphibia with _Gerobatrachus_: 278–361Ma (Median 320Ma)\
**948:** Lissamphibia without _Gerobatrachus_: 316–363Ma (Median 326Ma)\
**949:** Batrachia: 219–348Ma (Median 292Ma)\
**977:** Gymnophiona: 91.6–259Ma (Median 216Ma)

**$XXX ADD: 973:** Salamandroidea (Ambystomatidae + Salamandridae)

*This is Plesiophiona + Pseudophiona in the nomenclature of Dubois et al. 2021

<img width="2189" height="1529" alt="image" src="https://github.com/user-attachments/assets/cad59f92-345a-4dfe-a558-63c10ce5b2de" />

## References

Agnolin, F., de Souza Carvalho, I., Rolando, A.M.A., Novas, F.E., Xavier-Neto, J., Andrade, J.A.F.G. and Freitas, F.I., 2020. Early Cretaceous neobatrachian frog (Anura) from Brazil sheds light on the origin of modern anurans. Journal of South American Earth Sciences, 101, p.102633.

Anderson, J.S., Reisz, R.R., Scott, D., Fröbisch, N.B. and Sumida, S.S., 2008. A stem batrachian from the Early Permian of Texas and the origin of frogs and salamanders. Nature, 453(7194), pp.515-518.

Baez, A.M. and Gomez, R.O., 2016. Revision of the skeletal morphology of Eodiscoglossus santonjae, an Early Cretaceous frog from northeastern Spain, with comments on its phylogenetic placement. Acta Musei Nationalis Pragae Series B Historia Naturalis 72(1-2):66-77.

Chen, J., Bever, G.S., Yi, H.Y. and Norell, M.A., 2016. A burrowing frog from the late Paleocene of Mongolia uncovers a deep history of spadefoot toads (Pelobatoidea) in East Asia. Scientific Reports, 6(1), p.19209.

Dubois, A., Ohler, A. and Pyron, R.A., 2021. New concepts and methods for phylogenetic taxonomy and nomenclature in zoology, exemplified by a new ranked cladonomy of recent amphibians (Lissamphibia). Megataxa, 5(1), pp.1-738.

Feng, Y.J., Blackburn, D.C., Liang, D., Hillis, D.M., Wake, D.B., Cannatella, D.C. and Zhang, P., 2017. Phylogenomics reveals rapid, simultaneous diversification of three major clades of Gondwanan frogs at the Cretaceous–Paleogene boundary. Proceedings of the national Academy of Sciences, 114(29), pp.E5864-E5870.

Gao, K.Q. and Chen, J., 2017. A new crown-group frog (Amphibia: Anura) from the Early Cretaceous of northeastern Inner Mongolia, China. American Museum Novitates, 2017(3876), pp.1-39.

Gómez, R.O. and Lires, A.I., 2019. High ecomorphological diversity among Early Cretaceous frogs from a large subtropical wetland of Iberia. Comptes Rendus Palevol, 18(7), pp.711-723.

Hime, P.M., Lemmon, A.R., Lemmon, E.C.M., Prendini, E., Brown, J.M., Thomson, R.C., Kratovil, J.D., Noonan, B.P., Pyron, R.A., Peloso, P.L. and Kortyna, M.L., 2021. Phylogenomics reveals ancient gene tree discordance in the amphibian tree of life. Systematic biology, 70(1), pp.49-66.

Kligman, B.T., Gee, B.M., Marsh, A.D., Nesbitt, S.J., Smith, M.E., Parker, W.G. and Stocker, M.R., 2023. Triassic stem caecilian supports dissorophoid origin of living amphibians. Nature, 614(7946), pp.102-107.

Lucas, S.G., Henderson, C., Barrick, J.E. and Krainer, K., 2022. Middle Kungurian (Early Permian) seaways in the southwestern USA. Permophiles, 72, pp.48-51.

Pérez-Ben, C.M., Lires, A.I. and Gómez, R.O., 2024. Frog limbs in deep time: is jumping locomotion at the roots of the anuran Bauplan?. Paleobiology, 50(1), pp.96-107.

Stewart, A.A. and Wiens, J.J., 2025. A time-calibrated salamander phylogeny including 765 species and 503 genes. Molecular Phylogenetics and Evolution, 204, p.108272.
