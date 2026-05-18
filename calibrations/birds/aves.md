# Bird calibrations

Our bird calibrations are adapted primarily from Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)).


### Calibrations:

**Node 709:** Galloanserae | 92.73-65.65Ma\
**Node calibrated:** Last common ancestor of clade encompassing Galliformes (**$X**) and Anseriformes(**$X**)\
**Fossil taxa:** Numerous fossil taxa satisfying the criteria of Parham et al. ([2012](https://academic.oup.com/sysbio/article-abstract/61/2/346/1647963)) support this calibration. These are listed below with references justifying the synapomorphies or phylogenetic analyses allying them with the crown of Galloanserae:

  _Conflicto antarcticus_ Tambussi, Degrange, de Mendoza, Sferco, & Santillana, 2019 – a nearly complete skeleton (MLP 07-III-1-1) from Level 10 of the López de Bertodano Formation at Seymour Island, Antarctica. A cladistic analysis including a variety of extant and extinct galloanserines placed the holotype of Conflicto antarticus as a stem Anseriformes ([Tambussi et al. 2019](https://academic.oup.com/zoolinnean/article-abstract/186/3/673/5281199)), a result further supported by subsequent cladistic and Bayesian analyses ([Field et al. 2020](https://www.nature.com/articles/s41586-020-2096-0), [Musser & Clarke 2024](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0278737)).

  _Presbyornis mongoliensis_ Kurochkin & Dyke, 2009 – tarsometatarsals (PIN 3104-6, 3104-24) from the Naran and Zhygden members of Tsagaan Khushuu, southern Gobi Desert, Ömnögovi Aimag, Mongolia (Paleocene, 58.7–55.8Ma), Mongolia ([Kurochkin & Dyke 2009](https://onlinelibrary.wiley.com/doi/10.1002/gj.1177)).

_Anachronornis anhimops_ Houde, Dickson, & Camerena, 2023 – nearly complete skeleton including the skull (USNM 496700) from site T56N R101W, Clark Quadrangle, Park County, Wyoming. Dated as latest Thanetian (56.22–55.80Ma). Phylogenetic analyses recovered _Anachronornis_ as a stem Anseriformes ([Houde et al. 2023](https://www.mdpi.com/1424-2818/15/2/233)).

_Nettapterornis oxfordi_ ([Olson 1999](https://repository.si.edu/items/a9f15a68-b2e8-45c5-92ef-cf4ed854a469)) – articulated partial skeleton (BMNH Paleo A5922) from London Clay at Walton-on-the-Naze (early Ypresian, 54.6–55Ma), United Kingdom. Phylogenetic analyses place this taxon at either the stem or the crown of Anseriformes ([Mayr & Kitchener 2025](https://link.springer.com/article/10.1007/s12542-025-00730-3)).

Unnamed anseriform – partial quadrate (QM F23019) from the Tingamarra Local Fauna (early Eocene, 54.65–54.55Ma) of Murgon, Queensland, Australia ([Elzanowski & Boles 2012](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1475-4983.2012.01166.x)).

_Namaortyx sperrgebietensis_ Mourer-Chauviré, Pickford, & Senut, 2011 – almost complete tarsometatarsus (GSN No. SS 8’08) from the Middle Eocene (49-47Ma) of Namibia ([Mourer-Chauviré et al. 2011](https://ui.adsabs.harvard.edu/link_gateway/2011JOrni.152..617M/doi:10.1007/s10336-010-0630-9)).

_Chaunoides antiquus_ [Alvarenga, 1999](https://www.biodiversitylibrary.org/item/266361#page/233/mode/1up) – associated bones of at least three individuals (MNRJ 4619-V to 4632-V) from montmorillonite clays of the Tremembé Formation at Fazenda Santa Fé, Sao Paulo, Brazil (late Oligocene to early Miocene, 27.3–16Ma). Phylogenetic analysis confirmed this fossil as a stem Anhimidae ([Musser & Clarke 2024](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0278737)).

_Manuherikia lacustrina_ Worthy, Tennyson, Jones, McNamara, & Douglas, 2007 – isolated long bones (MNZ S40094, S42306-8) from the Bannockburn Formation, St Bathans Fauna (Antonian, 19–16Ma), Otago, New Zealand ([Worthy et al. 2007](https://www.tandfonline.com/doi/abs/10.1017/S1477201906001957), [Worthy & Lee 2008](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1475-4983.2008.00778.x)).
 
**Minimum age:** 65.65Ma\
**Minimum justification:** The oldest of these fossils, _Conflicto antarcticus_, is from Level 10 of the López de Bertodano Formation, which is the youngest stratum of the formation and sits right above the K-Pg boundary (66.04Ma); its upper bound was estimated as 65.65Ma based on dinoflagellate cyst biostratigraphy and U–Pb zircon dating ([Bowman et al. 2016](https://www.sciencedirect.com/science/article/pii/S1342937X15002828)).\
**Maximum age:** 91.91Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Galloanseres on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** While we simplify the CladeDate results for boundaries that are compatible with mcmctree and treePL, the original calibration function results in a skewStudent distribution with xi=6.573e+01, omega=6.415e+00, alpha=4.680e+07, and nu=2.143e+00.


### Notes
**DJF:** Just wondering if it would make sense to add any internal calibrations for Palaeognathae? I think _Emuarius gidju_ is clearly a total-clade casuariid, so it could calibrate the _Dromaius_-_Apteryx_ node in the tree at ~24.5Ma. **SC:** But _Emuarius_ is sister to _Dromaiaus_ (Worthy et al. 2014), thus calibrating crown Casuariiformes. It would be a stretch to use it for the much deeper node you mention. Unfortunately, we don't have _Cassuarius_ in the dataset.

**DJF:** I like Romainvillia as a calibration for crown Anseres (Anatidae + Anseranatidae), but it looks like Anhimidae and Anseranas are not included in the tree [re: Node 709]

**DJF:** Crown Columbimorphae? Santiago and Josefin, since the Pteroclidae + Columbidae split is represented in the tree, should we calibrate that node? I think Leptoganga sepultus provides a good calibration for that node. Since it is thought to be a stem-sandgrouse, it would calibrate the sandgrouse-pigeon divergence at 23.9Ma based on the age of the Quercy fissure fillings. **SC:** Is there a phylogenetic analysis of Leptoganga?

**DJF:** Deeper within Strisores it could be possible to calibrate some of the divergences within 'Caprimulgiformes'. For instance, since _Prefica_ looks like a stem-Oilbird (and we assume monophyly of Sedentaves, i.e. Steatornis + Nyctibiidae), then _Prefica_ would provide a calibration for the MRCA of _Nyctibius_ and its sister taxon in the tree at 51.8Ma.

**DJF:** The sampling in the tree would allow calibration of crown Gruidae (MRCA of _Balearica_ and _Grus_) at 10.3Ma using _Balearica exigua_ (although I think it would be interesting to revisit this taxon). **SC:** a potentially good addition, but there is no phylogenetic analysis of B. exigua.

**Node 612:** Passerellidae and allies | XX-7.5Ma\
**Node calibrated:** Last common ancestor of clade encompassing Passerellidae and Icteridae + Parulidae\
**Fossil taxa:** Palaeostruthus hatcheri (holotype USNM 6647). Palaeostruthus hatcheri (Shufeldt, 1913), rostrum maxillae (holotype USNM 6647). It was collected from "Quarry E" near Long Island in Phillips County, Kansas, United States of America.\
**Minimum age:** 7.5Ma\
**Minimum justification:** The holotype is from the Barstovian–Hemphillian (Miocene-Pliocene) Ogallala Formation. The deposits at Long Island quarry are early Hemphillian (Hh1; late Miocene) (Janis et al. 2008). This gives an estimated age of 9.0–7.5Ma for the fossil, based on Hh1 boundaries in Hilgen et al. (2012).\
**Maximum age:** XXXMa\
**Maximum justification:**\
**Discussion:** **SC:** This fossil has never been analyzed using phylogenetic methods and its affinities are a matter of opinion. Let's not use this one unless we determine that it may be needed. **DJF:** I don't disagree that the fossil is potentially controversial, although Dan and I looked carefully at this one when we were working on the Oliveros et al. passerine paper and had to agree that everything is consistent with a referral to at least a broader emberizoid subclade including Passerellidae. **SC:** I think it can be referred to Passerellidae, in particular. Could add this calibration but would not be compliant with the Parham "best practices" because of a lack of phylogenetic analysis.

## References

Alvarenga, H.M., 1999. A Fossil Screamer (Anseriformes: Anhimidae) from the Middle Tertiary of Southeastern Brazil. Smithsonian Contributions to Paleobiology, (89) 223-230.

Bowman, V., J. Ineson, J. Riding, J. Crame, J. Francis, D. Condon, R. Whittle & F. Ferraccioli. 2016. The Paleocene of Antarctica: Dinoflagellate cyst biostratigraphy, chronostratigraphy and implications for the palaeo-Pacific margin of Gondwana. Gondwana Research 38:132-148.

Claramunt, S., 2022. CladeDate: Calibration information generator for divergence time estimation. Methods in Ecology and Evolution, 13(11), pp.2331-2338.

Elzanowski A, Boles WE. 2012 Australia’s oldest Anseriform fossil: a quadrate from the Early Eocene Tingamarra Fauna. Palaeontology 55, 903–911.

Field, D. J., J. Benito, A. Chen, J. W. M. Jagt, D. T. Ksepka 2020. Late Cretaceous neornithine from Europe illuminates the origins of crown birds. Nature 579 (7799): 397–401.

Houde, P., Dickson, M., & Camarena, D. (2023). Basal anseriformes from the early Paleogene of North America and Europe. Diversity, 15(2), 233.

Kurochkin E. N. & A. A. Dyke 2009. A large collection of Presbyornis (Aves, Anseriformes, Presbyornithidae) from the late Paleocene and early Eocene of Mongolia. Geological Journal 45:375-387.

Mayr, G., & Kitchener, A. C. (2025). Leg bones of the anseriform taxon Nettapterornis from the London Clay of Walton-on-the-Naze and notes on the bony-toothed birds from this locality. PalZ, 99(3), 355-369.

Mourer-Chauvire, Pickford & Senut 2011. The first Palaeogene galliform from Africa. Journal of Ornithology 152 3:617-622

Musser, G., & J. A. Clarke 2024. A new Paleogene fossil and a new dataset for waterfowl (Aves: Anseriformes) clarify phylogeny, ecological evolution, and avian evolution at the K-Pg Boundary. Plos one, 19(7), e0278737.

Olson, S.L., 1999. The anseriform relationships of Anatalavis Olson and Parris (Anseranatidae), with a new species from the Lower Eocene London Clay. Smithsonian Contributions to Paleobiology, 89, pp.231-243.

Parham, J.F., Donoghue, P.C., Bell, C.J., Calway, T.D., Head, J.J., Holroyd, P.A., Inoue, J.G., Irmis, R.B., Joyce, W.G., Ksepka, D.T. and Patané, J.S., 2012. Best practices for justifying fossil calibrations. Systematic biology, 61(2), pp.346-359.

Stiller, J., Feng, S., Chowdhury, A.A., Rivas-González, I., Duchêne, D.A., Fang, Q., Deng, Y., Kozlov, A., Stamatakis, A., Claramunt, S. and Nguyen, J.M., 2024. Complexity of avian evolution revealed by family-level genomes. Nature, 629(8013), pp.851-860.

Tambussi, C.P., F.J. Degrange, R.S. De Mendoza, E. Sferco & S. Santillana. 2019. A stem anseriform from the early Palaeocene of Antarctica provides new key evidence in the early evolution of waterfowl. Zoological Journal of the Linnean Society 186(3):673-700.

Worthy, T. H., A. J. D. Tennyson, C. Jones, J. A. McNamara & B. J. Douglas. 2007. Miocene waterfowl and other birds from Central Otago, New Zealand. Journal of Systematic Palaeontology 5:1–39.

Worthy T.H. & M. S. Y.  Lee. 2008. Affinities of Miocene (19–16 Ma) waterfowl (Anatidae: Manuherikia, Dunstanetta and Miotadorna) from the St Bathans Fauna, New Zealand. Palaeontology 51: 677–708.
