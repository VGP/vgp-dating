# Bird calibrations

Our bird calibrations are primarily adapted from Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)). Calibration parameters were derived from the fossil record using the CladeDate method ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)). The set of fossil ages represent the first fossil occurrence of a taxon in each continent. The minimum age is the minimum possible age (upper stratigraphic bound) of the oldest fossil. The maximum age was obtained from the 95% quantile of the empirical distribution obtained from CladeDate. The parameters of a skew-Student distribution fitted to the empirical distribution are also provided. In general, we attempt to ensure that the oldest fossil constraining the minimum bound on each node age satisfies the criteria of Parham et al. ([2012](https://doi.org/10.1093/sysbio/syr107)).

CAL identifiers refer to records in the [master calibration list](../master_calibrations.csv). Tree mappings give the corresponding node numbers in [ROADIES v0.0.0](../../trees/roadies_v1.1.16b.numbers.nwk) (`roadies_v1.1.16b`) and [ASTRAL v0.1.1](../../trees/astralpro.l6p1.numbers.nwk) (`astralpro.l6p1`).

### Calibrations:

**CAL084:** Galloanserae | 65.7–91.9Ma\
**Tree mapping:** ROADIES node 709; ASTRAL node 1000\
**Node calibrated:** Last common ancestor of the clade encompassing Galliformes (_Gallus gallus_) and Anseriformes (_Anser anser_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Conflicto antarcticus_ [Tambussi, Degrange, de Mendoza, Sferco, & Santillana, 2019](https://doi.org/10.1093/zoolinnean/zly085) – a nearly complete skeleton (MLP 07-III-1-1) from Level 10 of the López de Bertodano Formation at Seymour Island, Antarctica. A cladistic analysis including a variety of extant and extinct galloanserines placed the holotype of †_Conflicto antarcticus_ as a stem Anseriformes ([Tambussi et al. 2019](https://doi.org/10.1093/zoolinnean/zly085)), a result further supported by subsequent cladistic and Bayesian analyses ([Field et al. 2020](https://www.nature.com/articles/s41586-020-2096-0), [Musser & Clarke 2024](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0278737)).

- †_Presbyornis mongoliensis_ [Kurochkin & Dyke, 2009](https://doi.org/10.1002/gj.1177) – tarsometatarsals (PIN 3104-6, 3104-24) from the Naran and Zhygden members of Tsagaan Khushuu, southern Gobi Desert, Ömnögovi Aimag, Mongolia (Paleocene, 58.7–55.8Ma) ([Kurochkin & Dyke 2009](https://doi.org/10.1002/gj.1177)).

- †_Anachronornis anhimops_ [Houde, Dickson, & Camerena, 2023](https://doi.org/10.3390/d15020233) – nearly complete skeleton including the skull (USNM 496700) from site T56N R101W, Clark Quadrangle, Park County, Wyoming. Dated as latest Thanetian (56.22–55.80Ma). Phylogenetic analyses recovered †_Anachronornis_ as a stem Anseriformes ([Houde et al. 2023](https://doi.org/10.3390/d15020233)).

- †_Nettapterornis oxfordi_ ([Olson 1999](https://repository.si.edu/items/a9f15a68-b2e8-45c5-92ef-cf4ed854a469)) – articulated partial skeleton (BMNH Paleo A5922) from London Clay at Walton-on-the-Naze (early Ypresian, 54.6–55Ma), United Kingdom. Phylogenetic analyses place this taxon at either the stem or the crown of Anseriformes ([Mayr & Kitchener 2025](https://link.springer.com/article/10.1007/s12542-025-00730-3)).

- Unnamed anseriform – partial quadrate (QM F23019) from the Tingamarra Local Fauna (early Eocene, 54.65–54.55Ma) of Murgon, Queensland, Australia ([Elzanowski & Boles 2012](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1475-4983.2012.01166.x)).

- †_Namaortyx sperrgebietensis_ [Mourer-Chauviré, Pickford, & Senut, 2011](https://doi.org/10.1007/s10336-010-0630-9) – almost complete tarsometatarsus (GSN No. SS 8’08) from the Middle Eocene (49–47Ma) of Namibia ([Mourer-Chauviré et al. 2011](https://doi.org/10.1007/s10336-010-0630-9)).

- †_Chaunoides antiquus_ [Alvarenga, 1999](https://www.biodiversitylibrary.org/item/266361#page/233/mode/1up) – associated bones of at least three individuals (MNRJ 4619-V to 4632-V) from montmorillonite clays of the Tremembé Formation at Fazenda Santa Fé, Sao Paulo, Brazil (late Oligocene to early Miocene, 27.3–16Ma). Phylogenetic analysis confirmed this fossil as a stem Anhimidae ([Musser & Clarke 2024](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0278737)).

- †_Manuherikia lacustrina_ [Worthy, Tennyson, Jones, McNamara, & Douglas, 2007](https://doi.org/10.1017/S1477201906001957) – isolated long bones (MNZ S40094, S42306-8) from the Bannockburn Formation, St Bathans Fauna (Antonian, 19–16Ma), Otago, New Zealand ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957), [Worthy & Lee 2008](https://doi.org/10.1111/j.1475-4983.2008.00778.x)).

**Minimum age:** 65.65Ma\
**Minimum justification:** The oldest of these taxa, †_Conflicto antarcticus_, is from Level 10 of the López de Bertodano Formation, which is the youngest stratum of the formation and sits right above the K-Pg boundary (66.04Ma); its upper bound was estimated as 65.65Ma based on dinoflagellate cyst biostratigraphy and U–Pb zircon dating ([Bowman et al. 2016](https://www.sciencedirect.com/science/article/pii/S1342937X15002828)).\
**Maximum age:** 91.91Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Galloanserae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** The CladeDate calibration function results in a skew-Student distribution with ξ = 65.73, ω = 6.415, α = 4.680e+07, and ν = 2.143.

---

**CAL085:** Anatidae | 24.0–38.1Ma\
**Tree mapping:** ROADIES node 710; ASTRAL node 1004\
**Node calibrated:** Last common ancestor of Anatinae (_Anas platyrhynchos_) and Anserinae (_Anser anser_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Pinpanetta tedfordi_ [Worthy, 2009](https://doi.org/10.1111/j.1096-3642.2008.00483.x) – complete right humerus (SAMA P.41257) from the Etadunna Formation at Young Bucks Quarry, Lake Palankarinna, South Australia, Australia. This locality is shared with three other contemporaneous fossil ducks: †_P. vickersrichae_ and †_P. fromensis_, and †_Australotadorna alecwilsoni_ ([Worthy 2009](https://doi.org/10.1111/j.1096-3642.2008.00483.x)). A cladistic analysis of †_Pinpanetta_ (including †_P. tedfordi_) placed it as a stem member of Erismaturinae ([Worthy 2009](https://doi.org/10.1111/j.1096-3642.2008.00483.x)).

- †_Mionetta blanchardi_ ([Milne-Edwards, 1863](https://www.biodiversitylibrary.org/page/3679973#page/1224/mode/1up)) – multiple bones from several individuals including UCBL-FSL 442.807 and 442.800 from Saint-Gérand-le-Puy (Aquitanian, 23–20.4Ma), Allier, France ([Worthy & Lee 2008](https://doi.org/10.1111/j.1475-4983.2008.00778.x)).

- †_Mionetta_ sp. – distal humerus (GSN GT 133’06) from Grillental (early Miocene, 20Ma), Northern Sperrgebiet, Namibia ([Mourer-Chauviré 2008](https://www.researchgate.net/publication/285787143_Birds_Aves_from_the_Early_Miocene_of_the_Northern_Sperrgebiet_Namibia)).

- †_Manuherikia lacustrina_ [Worthy, Tennyson, Jones, McNamara, & Douglas, 2007](https://doi.org/10.1017/S1477201906001957) – isolated long bones (MNZ S40094, S42306-8) from the Bannockburn Formation, St Bathans Fauna (Antonian, 19–16Ma), Otago, New Zealand ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957), [Worthy & Lee 2008](https://onlinelibrary.wiley.com/doi/abs/10.1111/j.1475-4983.2008.00778.x)).

- Bone fragments representing multiple anatid genera are known from Sharga (Middle Miocene, NMU7, MN7–8, 13.1–11.2Ma), Shargyn-Govi area, Mongolia ([Zelenkov 2011](https://doi.org/10.1134/S0031030111020195)). These include †_Sharganetta mongolica_ [Zelenkov, 2011](https://doi.org/10.1134/S0031030111020195) (PIN 4869/195, 4869/198), †_Nogusunna conflictoides_ [Zelenkov, 2011](https://doi.org/10.1134/S0031030111020195) (PIN 4869/23, 4869/197, 4869/199), †_Protomelanitta gracilis_ [Zelenkov, 2011](https://doi.org/10.1134/S0031030111020195) (PIN 4869/100, 4869/125, 4869/134, 4869/151), and †_Chenoanas deserta_ [Zelenkov, 2012](https://doi.org/10.1134/S0031030112050139) (PIN 4869/57, 4869/196). 

- †_Megalodytes morejohni_ [Howard, 1992](https://www.biodiversitylibrary.org/item/348547#page/273/mode/1up) – long bones (LACM 123991–3, 123995) from the Round Mountain Member of the Temblor Formation (Langhian, 15.99–11.63Ma), Kern County, California, USA ([Howard 1992](https://www.biodiversitylibrary.org/item/348547#page/273/mode/1up)). 

- †_Chloephaga robusta_ [Tambussi, 1998](https://raco.cat/index.php/BolletiSHNBalears/article/view/169326) – distal ulna (MLP 57-VIl-23-47) from the Irene Formation (early Pliocene, 4–3Ma), Buenos Aires, Argentina ([Tambussi 1998](https://raco.cat/index.php/BolletiSHNBalears/article/view/169326)). There are many other fossils from this locality referred to Anatidae, but they most likely represent stem taxa.

- †_Alopochen sirabensis_ ([Andrews, 1897](https://onlinelibrary.wiley.com/doi/10.1111/j.1474-919X.1897.tb03281.x)) – bone fragments (UA 360) from the Pleistocene of Ampasambazimba (0.0229–0.0222Ma), Madagascar ([Goodman 1999](https://www.internationalornithology.org/PROCEEDINGS_Durban/Symposium/S50/S50.4.htm)).

**Minimum age:** 24Ma\
**Minimum justification:** Given the uncertainty in the relationships among anatid subfamilies, we use †_Pinpanetta_ to calibrate crown Anatidae. Biostratigraphy of fossil land mammals, presence of Oligocene foraminiferal fauna, and magnetostratigraphy indicate an age of ~24–26Ma for the Etadunna Formation ([Woodburne et al. 1994](https://doi.org/10.1080/02724634.1994.10011527)).\
**Maximum age:** 38.05Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Anatidae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** The CladeDate calibration function results in a skew-Student distribution with ξ = 24.701, ω = 3.477, α = 10.192, and ν = 2.627.

---

**CAL086:** Otidimorphae | 51.8–80.4Ma\
**Tree mapping:** ROADIES node 699; ASTRAL node 1022\
**Node calibrated:** Last common ancestor of Otidiformes (_Chlamydotis macqueenii_), Musophagiformes (_Tauraco erythrolophus_), and Cuculiformes (_Cuculus canorus_), sensu Braun et al. ([2019](https://link.springer.com/chapter/10.1007/978-3-030-16477-5_6))\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Foro panarium_ [Olson, 1992](http://hdl.handle.net/10088/8418) – nearly complete skeleton (USNM 336621) from the Fossil Butte Member (52.13–51.81Ma) of the Green River Formation at Thompson Quarry, Lincoln County, Wyoming, USA. Phylogenetic analysis placed this taxon in the stem of Musophagiformes ([Field & Hsiang 2018](https://doi.org/10.1186/s12862-018-1212-3)). 

- †_Chambicuculus pusillus_ [Mourer-Chauviré, Tabuce, Essid, Marivaux, Khayati, Vianey-Liaud, & Ben Haj Ali, 2013](https://www.researchgate.net/publication/325753653_A_small_galliform_and_a_small_cuculiform_from_the_Eocene_of_Tunisia) – represented by fragments of multiple bones (ONM CB1-541, CB1-560–4, CB2-1001) from the Eocene (51–44.6Ma; [Coster et al. 2012](https://doi.org/10.1130/B30565.1)) of Djebel Chambi, Tunisia ([Mourer-Chauviré et al. 2016](https://doi.org/10.18563/pv.40.1.e2)).

- †_Eocuculus_ cf. _cherpinae_ [Chandler, 1999](https://www.npshistory.com/publications/paleontology/grdtr-99-03-4.pdf) – partial postcranial skeleton (SMF Av 425) from the Early Oligocene (MP24, 30–28.8Ma) of Pichovet, France ([Mayr 2006](https://doi.org/10.1016/j.geobios.2005.10.007)).

- Otididae indet. from the Oligocene (33.9–23.0Ma) of Tchelkar Nura, Kazakhstan ([Kurochkin 1976](https://www.biodiversitylibrary.org/part/352126)). This material is not referenced to the specimen level, nor are explicit synapomorphies or phylogenetic analyses provided, but it is included here by reference for the sake of completeness.

- †_Centropus bairdi_ [Shute, Prideaux, & Worthy, 2016](https://doi.org/10.1111/zoj.12387) – long bones (WAM 09.3.277–282) from Leaena’s Breath Cave, Nullarbor Plain, Western, Australia ([Shute et al. 2016](https://doi.org/10.1111/zoj.12387)). Magnetostratigraphy and faunistic correlates suggest an early Pleistocene age within the Naracoortean land mammal age (2.58–0.78Ma; [Shute et al. 2016](https://doi.org/10.1111/zoj.12387)).

- _Crotophaga ani_ [Linnaeus, 1758](https://www.biodiversitylibrary.org/bibliography/542) – humeri and partial mandible, likely uncatalogued in the Natural History Museum of Denmark (formerly the University of Copenhagen Zoological Museum), from Lapa da Escrivania level 5, Lagoa Santa, Minas Gerais, Brazil ([Winge 1887](https://www.biodiversitylibrary.org/bibliography/13380), [Nascimento & Silveira 2020](https://doi.org/10.11646/zootaxa.4743.4.2)). This formation contains remains deposited during the Pleistocene-Holocene transition, about 0.012–0.010Ma ([Nascimento & Silveira 2020](https://doi.org/10.11646/zootaxa.4743.4.2)).

- Various fragmentary remains (DLC 17268, 18041, 18098, 18157, 18780, 18797, 18876) of five species of _Coua_ (Cuculidae) from Ankilitelo Cave (0.013–0.002Ma) Madagascar ([Goodman et al. 2013](https://doi.org/10.11646/zootaxa.3750.5.6)). 

**Minimum age:** 51.81Ma\
**Minimum justification:** The oldest of these taxa is †_Foro panarium_, for which radiometric 40Ar/39Ar-dating of the K-spar tuff near the top of the Fossil Butte member yielded a recalibrated date of 51.97±0.16Ma (Smith et al. [2008](https://doi.org/10.1130/B26073.1), [2010](https://doi.org/10.1130/G30630.1)).\
**Maximum age:** 80.39Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Otidimorphae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Relationships among Otidiformes, Musophagiformes and Cuculiformes are poorly resolved due to a very short internode and high levels of incomplete lineage sorting ([Stiller et al. 2024](https://doi.org/10.1038/s41586-024-07323-1)). We applied this calibration based on †_Foro panarium_ (Musophagiformes _incertae sedis_) to the entire crown group, noting that both it and †_Eocuculus_ have been very difficult to place phylogenetically – support for a position within Musophagiformes and Otidimorphae, respectively, are ambiguous across analyses. The CladeDate calibration function results in a skew-Student distribution with ξ = 51.91, ω = 7.378, α = 6.311e+05, and ν = 2.763.

---

**CAL087:** Daedalornithes | 54.6–84.2Ma\
**Tree mapping:** ROADIES node 704; ASTRAL node 1034\
**Node calibrated:** Last common ancestor of Aegothelidae (_Aegotheles albertisi_) and Apodiformes (_Apus apus_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Eocypselus vincenti_ [Harrison 1984](https://natuurtijdschriften.nl/pub/521070) – referred material, a nearly complete skeleton (MGUH 29278) and two incomplete postcranial skeletons (MGUH 26729–30) from the early Eocene (55.8–54.6Ma) Fur Formation, Denmark (see [Mayr 2010](https://doi.org/10.1007/s12549-010-0043-z) and [Mayr & Kitchener 2024](https://doi.org/10.1111/ibi.13323) – though MGUH 29278 is also occupied by †_Pellornis mikkelseni_ [Bertelli, Chiappe, & Mayr 2011](https://doi.org/10.1080/14772019.2010.538730)). A cladistic analysis ([Ksepka et al. 2013](https://doi.org/10.1098/rspb.2013.0580)) and Bayesian analyses with topological constraints ([Chen et al. 2019](https://doi.org/10.3390/d11090143)) found †_E. vincenti_ on the stem of Apodiformes, but a total evidence Bayesian analysis indicated a position on the stem of Aegothelidae instead ([Chen et al. 2019](https://doi.org/10.3390/d11090143)). Either way, †_Eocypselus_ is confirmed as a basal crown Daedalornithes.

- †_Eocypselus rowei_ [Ksepka, Kulp, Nesbitt, Clarke, & Grande, 2013](https://doi.org/10.1098/rspb.2013.0580) – a complete skeleton (WDC CGR-109) from the Fossil Butte Member of the Green River Formation (Early Eocene, 51.97±0.16Ma), Wyoming, USA ([Ksepka et. al. 2013](https://doi.org/10.1098/rspb.2013.0580)).         

- †_Collocalia buday_ [Boles, 2001](https://publications.australian.museum/a-swiftlet-apodidae-collocaliini-from-the-miocene-of-riversleigh-northwestern-queensland/) – left humerus (QM F20907) from the early Miocene Camel Sputum Site (18.53–16.97Ma; [Woodhead et al. 2016](https://www.sciencedirect.com/science/article/abs/pii/S1342937X14003086)), Riversleigh, Queensland, Australia (see [Worthy & Nguyen 2020](https://doi.org/10.1080/03721426.2020.1756560)).

- †_Aegotheles zealandivetus_ [Worthy, Scofield, Salisbury, Hand, De Pietri, & Archer, 2022](https://doi.org/10.1007/s10336-022-01981-6) – various material (CM 2013.18.1127; NMNZ S.42800, S.52761, S.52917) from the Bannockburn Formation, St Bathans Fauna (Early Miocene, Altonian, 18.26–15.97Ma), Otago, New Zealand ([Worthy et al. 2022](https://doi.org/10.1007/s10336-022-01981-6)).

- _Tachymarptis_ sp. – a single humerus, currently undescribed, first reported by Rich ([1980](https://hdl.handle.net/10520/AJA00382353_1817)) from the upper Varswater Formation at Langebaanweg (Early Pliocene 5.33–3.6Ma), Cape Province, South Africa ([Manegold et al. 2013](https://www.researchgate.net/publication/259272396_The_Early_Pliocene_avifauna_of_Langebaanweg_South_Africa_a_review_and_update)).

- _Apus_ sp. – material representing a left coracoid (NSMT PV 24548), left carpometacarpus (24549), and proximal phalanx major digit (24550) from fissure-filling deposits in Shiriya, Aomori Prefecture, Japan; Late Pleistocene (~MIS 5e: 0.129–0.116Ma; [Watanabe et al. 2018](https://doi.org/10.4202/app.00509.2018)).

- _Streptoprocne zonaris_ ([Shaw, 1796](https://archive.org/details/bim_eighteenth-century_cimelia-physica-figures_shaw-george_1796)) – unspecified, possibly uncatalogued specimen from Barra do Antonião, Piauí, Brazil (Late Pleistocene: 0.129–0.0117Ma; [Guérin et al. 1996](https://www.researchgate.net/publication/291774116_A_fauna_pleistocenica_do_Piaui_Nordeste_do_Brasil_Relacoes_paleoecologicas_e_biocronologicas)).

**Minimum age:** 54.6Ma\
**Minimum justification:** The oldest of these fossils is †_Eocypselus vincenti_, for which the bottom of the Fur Formation was deposited during the recovery phase of the Paleocene-Eocene Thermal Maximum around 55.8Ma ago ([Stokke et al. 2020a](https://doi.org/10.30909/vol.03.02.227250)). Basalts at the top of the Formation correlate with “subphase 2b” of pyroclastic deposition in the Balder Formation, suggesting a minimum age of 54.6Ma ([King 2016](https://doi.org/10.1144/SR27), [Stokke et al. 2020b](https://doi.org/10.1016/j.epsl.2020.116388)).\
**Maximum age:** 84.22Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Daedalornithes on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 54.649, ξ = 55.022, ω = 7.722, α = 37.041, and ν = 2.233.

---

**CAL088:** Apodi | 50.3–103.4Ma\
**Tree mapping:** ROADIES node 708; ASTRAL node 1036\
**Node calibrated:** Last common ancestor of Apodidae (_Apus apus_) and Hemiprocnidae (_Hemiprocne comata_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Scaniacypselus wardi_ [Harrison, 1984](https://natuurtijdschriften.nl/pub/521070) – articulated pectoral girdle and forelimbs (BMNH A5430) from Bed R6 (50.3–51.5Ma) of the Røsnæs Clay Formation in Ølst, Denmark. Cladistic analyses ([Mayr 2003](https://doi.org/10.1642/0004-8038(2003)120[0145:POETSA]2.0.CO;2), [Ksepka et al. 2013](https://doi.org/10.1098/rspb.2013.0580)) and Bayesian analyses with topological constraints ([Chen et al. 2019](https://doi.org/10.3390/d11090143)) placed it on the stem of Apodidae.

- †_Collocalia buday_ [Boles, 2001](https://publications.australian.museum/a-swiftlet-apodidae-collocaliini-from-the-miocene-of-riversleigh-northwestern-queensland/) – left humerus (QM F20907) from the early Miocene Camel Sputum Site (18.53–16.97Ma; [Woodhead et al. 2016](https://www.sciencedirect.com/science/article/abs/pii/S1342937X14003086)), Riversleigh, Queensland, Australia (see [Worthy & Nguyen 2020](https://doi.org/10.1080/03721426.2020.1756560)).

- _Collocalia_ sp. from the Bannockburn Formation, St Bathans Fauna (Early Miocene, Altonian, 18.26–15.97Ma), Otago, New Zealand ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957)). Although not identified at the species level, it is estimated to be much smaller than †_Collocalia buday_ ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957)).
         
- _Tachymarptis_ sp. – a single humerus, currently undescribed, first reported by Rich ([1980](https://hdl.handle.net/10520/AJA00382353_1817)) from the upper Varswater Formation at Langebaanweg (Early Pliocene 5.33–3.6Ma), Cape Province, South Africa ([Manegold et al. 2013](https://www.researchgate.net/publication/259272396_The_Early_Pliocene_avifauna_of_Langebaanweg_South_Africa_a_review_and_update)).

- _Apus_ sp. – material representing a left coracoid (NSMT PV 24548), left carpometacarpus (24549), and proximal phalanx major digit (24550) from fissure-filling deposits in Shiriya, Aomori Prefecture, Japan; Late Pleistocene (~MIS 5e: 0.129–0.116Ma; [Watanabe et al. 2018](https://doi.org/10.4202/app.00509.2018)).
  
- _Streptoprocne zonaris_ ([Shaw, 1796](https://archive.org/details/bim_eighteenth-century_cimelia-physica-figures_shaw-george_1796)) – unspecified, possibly uncatalogued specimen from Barra do Antonião, Piauí, Brazil (Late Pleistocene: 0.129–0.0117Ma; [Guérin et al. 1996](https://www.researchgate.net/publication/291774116_A_fauna_pleistocenica_do_Piaui_Nordeste_do_Brasil_Relacoes_paleoecologicas_e_biocronologicas)).

- _Chaetura pelagica_ ([Linnaeus, 1758](https://www.biodiversitylibrary.org/bibliography/542)) from the Late Pleistocene (0.1–0.0117Ma) of Clark's Cave, Bath County, Virginia, USA ([Guilday et al. 1977](https://www.biodiversitylibrary.org/part/228581)).

**Minimum age:** 50.3Ma\
**Minimum justification:** The oldest fossil is †_Scaniacypselus wardi_, for which the top of Member R6 is overlaid conformably by the Lillebælt Clay Formation; its base coincides with a sharp transition from calcareous to non-calcareous foraminifera, including _Reticulophragmium amplectens_, which correlates with the NS18-NS19 boundary at around 50.3Ma ([King 2016](https://doi.org/10.1144/SR27), fig. 76). The lowest part of R6 (or the top of the underlying Member R5) shows the last occurrence of the dinoflagellate cysts _Ochetodinium romanum_, which represent the top of Subzone DE8b ([King 2016](https://doi.org/10.1144/SR27)) at around 51.5Ma ([Speijer et al. 2020](https://doi.org/10.1016/B978-0-12-824360-2.00028-0)). King ([2016](https://doi.org/10.1144/SR27)) shows a very narrow Subzone DE8b containing _Ochetodinium romanum_ and right after the polarity reversal in the middle of C23, which is 51.72Ma ([Speijer et al. 2020](https://doi.org/10.1016/B978-0-12-824360-2.00028-0)).\
**Maximum age:** 103.40Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Apodi on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 50.32, ξ = 50.68, ω = 11.39, α = 61.85, and ν = 1.90.

---

**CAL089:** Gruiformes | 55.6–80.4Ma\
**Tree mapping:** ROADIES node 675; ASTRAL node 1053\
**Node calibrated:** Last common ancestor of Gruoidea (_Grus grus_) and Ralloidea (_Gallinula chloropus_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Pellornis mikkelseni_ [Bertelli, Chiappe, & Mayr, 2011](https://doi.org/10.1080/14772019.2010.538730) – a nearly complete articulated skeleton (holotype MGUH 29278) from the Fur Formation near Sundby, Isle of Mors, Jutland, Denmark ([Hoch 1997](https://2dgf.dk/dgf-online-series/notes-on-palaeornithology-and-on-a-new-bird-from-the-early-tertiary-north-sea-region/), [Musser et al. 2019](https://doi.org/10.3390/d11070102)). Initial cladistic analyses indicated a position of †Messelornithidae, including †_Pellornis mikkelseni_, as stem Rallidae ([Bertelli et al. 2011](https://doi.org/10.1080/14772019.2010.538730)). More recent analyses including additional characters from a more complete preparation of the holotype revealing a complete skull among other parts, indicated a more basal position as stem Ralloidea ([Musser et al. 2019](https://doi.org/10.3390/d11070102), [Musser & Clarke 2020](https://doi.org/10.3389/fevo.2020.559929)), thus setting a minimum age for crown Gruiformes.

- †_Songzia acutunguis_ [Hou, 1990](https://www.vertpala.ac.cn/EN/volumn/volumn_134.shtml#1) – articulated skeletons (IVPP 18187–8) from the Yangxi Formation (55.8–48.6Ma), China ([Wang et al. 2012](https://doi.org/10.1080/03115518.2012.673302)), phylogenetically placed in †Messelornithidae by cladistic analysis ([Musser et al. 2019](https://doi.org/10.3390/d11070102)).

- †_Messelornis nearctica_ [Hesse, 1992](https://www.biodiversitylibrary.org/item/348547#page/213/mode/1up) – several skeletons (BHI 1283, 1292, 1294; FMNH A 716; SMF Av 406; SMNK-PAL 3810; USNM 336269, 336277, 776273, 776275) from the Fossil Butte Member of the Green River Formation (51.97±0.16Ma), Wyoming, USA ([Weidig 2010](https://journals.australian.museum/weidig-2010-rec-aust-mus-621-2944/)). See Musser et al. ([2019](https://doi.org/10.3390/d11070102)) for phylogenetic analysis.

- Rallidae indet. – distal end of left tarsometatarsus (DPC 3858) from the upper sequence of Quarry M in the Jebel Qatrani Formation (early Oligocene, 33.9–28.4Ma) at Fayum, Egypt ([Rasmussen et al. 1987](http://dx.doi.org/10.5479/si.00810266.62.1)).

- †_Australlus disneyi_ ([Boles, 2005](https://journals.australian.museum/boles-2005-rec-aust-mus-572-179190/)), specimens (QM F20906, F23723, F31469–76) from the White Hunter Site (Faunal Zone A, late Oligocene, 26–23.04Ma), Riversleigh, Queensland, Australia. Phylogenetic position determined by cladistic analysis ([Worthy & Boles 2011](https://doi.org/10.3853/j.0067-1975.63.2011.1563)).

- †?_Aptornis proasciarostratus_ [Worthy, Tennyson, & Scofield, 2011a](https://doi.org/10.1007/s10336-011-0649-6) – thoracic vertebrae (NMNZ S.52350, S.52353) from the Bannockburn Formation (early Miocene, Altonian, 18.26–15.97Ma) of Otago, New Zealand ([Worthy et al. 2011a](https://doi.org/10.1007/s10336-011-0649-6)). Although the Miocene fossils are fragmentary, the analysis of Quaternary fossils indicated that †_Aptornis_ belongs in crown Gruiformes, either in the Ralloidea ([Boast et al. 2019](https://doi.org/10.3390/d11020024)) or sister to Psophiidae ([Musser & Cracraft 2019](https://doi.org/10.1206/3927.1)).

- _Gallinula_ sp. and _Porzana_ sp. – unspecified, possibly uncatalogued specimens from the Late Pleistocene (0.129–0.0117Ma) at Barra do Antonião Piauí, Brazil ([Guérin et al. 1996](https://www.researchgate.net/publication/291774116_A_fauna_pleistocenica_do_Piaui_Nordeste_do_Brasil_Relacoes_paleoecologicas_e_biocronologicas)).

- Fragmentary remains of _Gallinula chloropus_ ([Linnaeus, 1758](https://www.biodiversitylibrary.org/bibliography/542)), _Porphyrio porphyrio_ ([Linnaeus, 1758](https://www.biodiversitylibrary.org/bibliography/542)), and †_Hovacrex roberti_ ([Andrews, 1897](https://onlinelibrary.wiley.com/doi/10.1111/j.1474-919X.1897.tb03281.x)) from Antsirabe (Holocene, 0.002–0Ma), Madagascar reported by Goodman ([1999](https://www.internationalornithology.org/PROCEEDINGS_Durban/Symposium/S50/S50.4.htm)) from the BMNH and UA collections (catalog numbers unspecified) and references therein.

**Minimum age:** 55.6Ma\
**Minimum justification:** The oldest of these fossils is †_Pellornis mikkelseni_, for which MGUH 29278 is preserved in silicified diatomite, and thus must derive from one of two horizons near ash layers -19 or -21 in the lower part of the Knudeklint Member. The bottom of the Fur Formation was deposited during the recovery phase of the Paleocene-Eocene Thermal Maximum around 55.8Ma ago ([Stokke et al. 2020a](https://doi.org/10.30909/vol.03.02.227250)). The younger ash layer -17 has been dated at 55.6±0.12Ma (corrected 40Ar/39Ar ages, [Stokke et al. 2020b](https://doi.org/10.1016/j.epsl.2020.116388)), providing a minimum age for the fossil.\
**Maximum age:** 80.40Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Gruiformes on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 55.629, ξ = 55.680, ω = 6.745, α = 160.041, and ν = 2.502.

---

**CAL090:** Charadriiformes | 55.0–78.6Ma\
**Tree mapping:** ROADIES node 666; ASTRAL node 1057\
**Node calibrated:** Last common ancestor of Charadrii (_Pluvialis apricaria_) and Scolopaci (_Numenius arquata_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- Unnamed taxon represented by the distal end of left humerus (IGM 100/1435) from Tsagaan Khushuu, Quarry 2, Mongolia, Bumban Member of the Naranbulag Formation of the early Eocene (Ypresian: 55.7–54.97Ma; [Hood et al. 2019](http://digitallibrary.amnh.org/handle/2246/6956)). Phylogenetic analysis placed this fragmentary bone as sister to _Chionis_, within crown Charadrii ([Musser & Clarke 2020](https://doi.org/10.3389/fevo.2020.559929), [Heingård et al. 2021](https://doi.org/10.3390/d13120651)).

- †_Charadriisimilis essexensis_ [Mayr & Kitchener 2023](https://doi.org/10.1017/jpa.2023.51) – incomplete skeleton (NMS.Z.2021.40.93) from Walton-on-the-Naze, Essex, United Kingdom, Walton Member of the Eocene London Clay Formation, early Ypresian (54.6–55Ma). Character comparisons and a cladistic analysis placed †_Charadriisimilis_ on the stem of the suborder Charadrii ([Mayr & Kitchener 2023](https://doi.org/10.1017/jpa.2023.51)).

- Unnamed taxon represented by the distal end of right humerus (SMF AV 619) from the Nanjemoy Formation at the Fisher/Sullivan site, Virginia, USA ([Mayr 2016](https://doi.org/10.1007/s12542-016-0330-8)). The bone shows apomorphic features of Charadriiformes ([Mayr 2016](https://doi.org/10.1007/s12542-016-0330-8)) and a cladistic analysis placed it within crown Charadriiformes ([Musser & Clarke 2020](https://doi.org/10.3389/fevo.2020.559929), [Heingård et al. 2021](https://doi.org/10.3390/d13120651)). The Nanjemoy Formation is ~54–53Ma ([Berggren et al. 1995](https://doi.org/10.7916/D8XD1B1H)).

- †_Nupharanassa bulotorum_ [Rasmussen, Olson, & Simons, 1987](http://dx.doi.org/10.5479/si.00810266.62.1) – distal tarsometatarsi (DPC 3848, 5327-8) from the Jebel Qatrani Formation at Quarry M (30.2–29.5Ma; [Seiffert 2006](https://doi.org/10.1073/pnas.0600689103)), Fayum Province, Egypt ([Rasmussen et al. 1987](http://dx.doi.org/10.5479/si.00810266.62.1)).

- †_Oligonomus milleri_ [De Pietri, Camens, & Worthy 2015](https://doi.org/10.1111/ibi.12215) – left coracoid (SAMA P27976) from member 7 of the Etadunna Formation at Lake Palankarinna (Faunal Zone B, 26–24Ma; [Woodburne et al. 1994](https://doi.org/10.1080/02724634.1994.10011527)), South Australia, Australia. Affinities with Pedionomidae based on combination of similarities ([De Pietri et al. 2015](https://doi.org/10.1111/ibi.12215)).

- †_Hakawai melvillei_ [De Pietri, Scofield, Tennyson, Hand, & Worthy, 2016](https://doi.org/10.1080/14772019.2015.1087064) – several bones (NMNZ S.50806 and numerous referred elements) from Bed HH4 of the Manuherikia River near St Bathans (Miocene: 19–16Ma), Otago, South Island, New Zealand. Derived characters suggest affinities with Pedionomidae ([De Pietri et al. 2016](https://doi.org/10.1080/14772019.2015.1087064)).

- Thinocoridae indet. – distal end of right tarsometatarsus (INGEO-PV 032) from upper portion of the Limolita La Colmena Member of the Loma de Las Tapias Formation at Loma de Las Tapias, San Juan Province, Argentina ([Agnolin et al. 2015](https://doi.org/10.1016/j.annpal.2015.11.002)). The fossil is estimated to be early Chasicoan (10–9Ma), with affinities based on presumed derived characters of the family ([Agnolin et al. 2015](https://doi.org/10.1016/j.annpal.2015.11.002)).

**Minimum age:** 54.97Ma\
**Minimum justification:** The oldest fossil is Charadrii indet., for which the estimated top of the Bumban Member of the Naranbulag Formation of Mongolia dates to the early Eocene (Ypresian: 55.7–54.97Ma; [Hood et al. 2019](http://digitallibrary.amnh.org/handle/2246/6956)).\
**Maximum age:** 78.61Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Charadriiformes on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Notes:** This is a new calibration for this analysis, not present in Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in a skew-Student distribution with ξ = 55.15, ω = 7.283, α = 9.888e+05, and ν = 2.875.

---

**CAL091:** Phaethontimorphae | 55.8–62.3Ma\
**Tree mapping:** ROADIES node 690; ASTRAL node 1041\
**Node calibrated:** Last common ancestor of clade encompassing Phaethontiformes (_Phaethon aethereus_) and Eurypygiformes (_Rhynochetos jubatus_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Lithoptila abounensis_ [Bourdon _in_ Bourdon et al. 2005](https://doi.org/10.1671/0272-4634(2005)025[0157:EANBAN]2.0.CO;2) – neurocranium (OCP.DEK/GE 1087) from the bed IIa of the Ouled Abdoun Phosphates Series (Thanetian, 58.7–55.8Ma), Ouled Abdoun Basin, Morocco ([Bourdon et al. 2005](https://doi.org/10.1671/0272-4634(2005)025[0157:EANBAN]2.0.CO;2)). A cladistic analysis placed †_L. abounensis_ sister to †_Prophaethon_, constituting a stem clade of Phaethontidae ([Bourdon et al. 2005](https://doi.org/10.1671/0272-4634(2005)025[0157:EANBAN]2.0.CO;2)).

- †_Zhylgaia aestiflua_ [Nessov, 1988](https://www.zin.ru/journals/trudyzin/eng/history.html) – two partial humeri (PO 3468, 3485) from the late Paleocene (58.7–55.8Ma) of Kazakhstan. Bourdon et al. ([2008](https://doi.org/10.1671/0272-4634(2008)28[751:NSOLAA]2.0.CO;2)) proposed placement in †Prophaethontiformes. †_Tshulia litorea_ [Nessov, 1988](https://www.zin.ru/journals/trudyzin/eng/history.html), based on a tarsometatarsus (PO 3470) and ulna (PO 3480) from the same locality ([Nessov 1992](https://www.biodiversitylibrary.org/item/348547#page/507/mode/1up)), represents the same taxon according to Mayr & Scofield ([2016](https://doi.org/10.1080/02724634.2015.1031343)).

- †_Prophaethon_ sp. – distal humerus (USNM 483158) from the Aquia Formation (Thanetian: 58.7–55.8Ma) at Capital Beltway and Central Avenue, Prince George’s County, Maryland, USA ([Olson 1994](http://hdl.handle.net/10088/6493)).

- †_Prophaethon shrubsolei_ Andrews, 1899 – partial neurocranium (SMF Av 602) from the Walton Member of the London Clay Formation at Walton-on-the-Naze (54–54.9Ma; [King 2016](https://doi.org/10.1144/sr27)), Essex, United Kingdom ([Mayr 2015a](https://doi.org/10.1111/ibi.12214)).

**Minimum age:** 55.8Ma\
**Minimum justification:** The oldest fossil is †_Lithoptila_, for which “[t]he specimen is dated as Thanetian (bed IIa of the mining lithostratigraphical terminology, Fig. 2) on the basis of the selachians identified in the matrix…” ([Bourdon et al. 2005](https://doi.org/10.1671/0272-4634(2005)025[0157:EANBAN]2.0.CO;2)), thus the upper boundary is 55.8Ma.\
**Maximum age:** 62.31Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Phaethontimorphae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 55.952, ξ = 57.879, ω = 1.273, α = 1.892, and ν = 2.901.

---

**CAL092:** Procellariimorphae | 60.5–84.7Ma\
**Tree mapping:** ROADIES node 689; ASTRAL node 1044\
**Node calibrated:** Last common ancestor of clade encompassing Sphenisciformes (_Spheniscus humboldti_) and Procellariiformes (_Calonectris borealis_).\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Waimanu manneringi_ [Jones, Ando, & Fordyce _in_ Slack et al. 2006](https://doi.org/10.1093/molbev/msj124) – associated partial postcranial skeleton (CM zfa35) from the Waipara Greensand (Paleocene, 61.6–60.5Ma), Waipara River, Canterbury, New Zealand ([Slack et al. 2006](https://doi.org/10.1093/molbev/msj124)). A number of other sphenisciform species have also recently been described from this formation ([Mayr et al. 2025](https://doi.org/10.1093/zoolinnean/zlaf080)), including the very well-preserved †_Daniadyptes primaevus_ (UC 22081–2), †_Waiparadyptes gracilitarsus_ (CM 2013.27.1; UC 22080, 22094), †_Archaeodyptes waitahaorum_ (CM 2020.46.1), and †_Waimanutaha kenlovei_ (CM 2010.108.1, 2018.124.4; UC 22079), all with the taxonomic authority [Mayr, De Pietri, Proffitt, Blokland, Clarke, Love, Mannering, Crouch, Reid, & Scofield, 2025](https://doi.org/10.1093/zoolinnean/zlaf080).

- †_Crossvallia unienwillia_ [Tambussi, Reguero, Marenssi, & Santillana, 2005](https://doi.org/10.1016/j.geobios.2004.02.003) – humerus, femur, partial tibiotarsus, and thoracic vertebra (MLP 00-I-10-1) from the Bahía Pingüino Member of the Cross Valley Formation at Seymour Island (Late Paleocene, 56–55Ma).

- †_Perudyptes devriesi_ [Clarke, Ksepka, Stucchi, Urbina, Giannini, Bertelli, Narváez, & Boyd, 2007](https://doi.org/10.1073/pnas.0611099104) – partial skeleton (MUSM 889) from the Paracas Formation (Middle Eocene, ~42Ma) at Quebrada Perdida, Peru.

- †"_Pachydyptes_" _simpsoni_ [Jenkins, 1974](https://palass.org/publications/palaeontology-journal/archive/17/2/article_pp291-310) – partial skeleton (SAMA P14157) from the Blanche Point Formation (Late Eocene: 38.0–36.5Ma; [Park & Fitzgerald 2012](https://doi.org/10.24199/j.mmv.2012.69.06)) Australia. Phylogenetically placed by Ksepka et al. ([2006](https://doi.org/10.1111/j.1096-0031.2006.00116.x)) and Ksepka & Clarke ([2012](http://hdl.handle.net/2246/6065)).

- †_Makahala mirae_ [Mayr, 2015b](https://doi.org/10.1127/njgpa/2015/0445) – wing bones (SMF Av 603) from Jansen Creek Member of the Makah Formation (Rupelian: 33.9–28.4Ma), near the mouth of Bullman Creek, Clallam County, Washington, USA ([Mayr 2015b](https://doi.org/10.1127/njgpa/2015/0445)).

- †_Rupelornis definitus_ [van Beneden, 1871](https://www.biodiversitylibrary.org/item/28485#page/278/mode/1up) – numerous elements (IRSNB Av 102–114) from the lower part of the Boom Formation, Rupel Group, middle Rupelian (early Oligocene, 31.5–30.5Ma), Belgium ([Mayr & Smith 2012](https://doi.org/10.1111/j.1096-3642.2012.00858.x)). Additional partial and complete skeletons of †_Rupelornis_ occur at Frauenweiler, Germany (32–30.5Ma), including SMNK-PAL 3812 (identified as †_Rupelornis_ cf. _brodkorbi_) and SMNS 85947/1 (preserving feathers); some material from this locality may be conspecific with †_R. definitus_ ([Maxwell et al. 2016](https://doi.org/10.1016/j.palaeo.2016.10.002)). Assigned to †Diomedeoididae, which is most probably a stem group of Procellariiformes ([De Pietri et al. 2009](https://doi.org/10.4202/app.2009.0069), [Mayr & Smith 2012](https://doi.org/10.1111/j.1096-3642.2012.00858.x)).

- Stem-group material apparently related to the Pliocene species †_Inguza predemersus_ ([Simpson, 1971](https://doi.org/10.1126%2Fscience.171.3976.1144)), †_Dege hendeyi_ [Simpson, 1979a](https://www.biodiversitylibrary.org/page/40687242#page/19/mode/1up), †_Nucleornis insolitus_ [Simpson, 1979b](https://www.biodiversitylibrary.org/item/126255#page/19/mode/1up), and †?_Palaeospheniscus huxleyorum_ [Simpson, 1973](https://journals.co.za/doi/epdf/10.10520/AJA00382353_4787), assigned to 'Sphenisciformes species A' resembling †_N. insolitus_ (SAM PQSS000211-1, PQSS000214-1, PQSS000217-2, PQSS000217-3, PQSS000220, PQSS000223-7) and 'Sphenisciformes species C' resembling †_I. predemersus_, †_D. hendeyi_, and †?_P. huxleyorum_ (SAM PQSS000211-2, PQSS000213, PQSS000214-2, PQSS000217-1, PQSS000223-5) from the Varswater Formation (late Miocene: 11.6–7.2Ma) at Saldanha Steel, South Africa ([Thomas & Ksepka 2013](https://doi.org/10.1111/zoj.12024)).

- _Phoebastria_ cf. _albatrus_ ([Pallas, 1769](https://doi.org/10.5962/bhl.title.39832)) – right humeral shaft (KUGM FA 2018.007) from the Hirayama Formation (early Pleistocene, 1.7Ma), Japan ([Watanabe et al. 2019](https://doi.org/10.1080/02724634.2019.1697277)).

- _Puffinus pacificus_ ([Gmelin, 1789](https://www.biodiversitylibrary.org/item/83107#page/66/mode/1up)) – at least two individuals (MHNR MHN-RUN-FE-O 1833–7, 1919) from Holocene deposits (~300–1700AD) in Marais de l'Ermitage, Reunión Island, Mascarene Islands ([Mourer-Chauviré et al. 1999](http://dx.doi.org/10.5479/si.00810266.89.1)). 

**Minimum age:** 60.5Ma\
**Minimum justification:** Dated by nannofossil biostratigraphy of the oldest taxon, †_Waimanu_. The matrix of the holotype CM zfa35 contained the coccolithophores _Chiasmolithus bidens_ and _Hornibrookina teurensis_ which indicate an age between 61.6 and 60.5Ma ([Slack et al. 2006](https://doi.org/10.1093/molbev/msj124)). †_W. manneringi_ is nearly coeval with several other fossil penguins but its age is better constrained, and its minimum possible age, in particular, is older than the others ([Blokland et al. 2019](https://doi.org/10.26879/1009)).\
**Maximum age:** 84.70Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Procellariimorphae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 60.530, ξ = 60.845, ω = 6.749, α = 37.833, and ν = 2.655.

---

**CAL093:** Accipitrimorphae + Strigiformes | 58.8–74.4Ma\
**Tree mapping:** ROADIES node 653; ASTRAL node 1067\
**Node calibrated:** Last common ancestor of clade encompassing Strigiformes (_Athene noctua_) and Accipitriformes (_Buteo buteo_).\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Ogygoptynx wetmorei_ [Rich & Bohaska, 1976](https://doi.org/10.5479/si.00810266.27.87) – tarsometatarsus (AMNH 2653) from the Late Paleocene of Mason Pocket (Ti-4a, Tiffanian NALMA, 58.8–59.5Ma; [Secord et al. 2006](https://doi.org/10.2475/ajs.306.4.211)), Colorado, USA ([Rich & Bohaska 1976](https://doi.org/10.5479/si.00810266.27.87)).

- †_Berruornis halbedeli_ [Mayr, 2007](https://doi.org/10.1671/0272-4634(2007)27[394:TBFTPF]2.0.CO;2) – Right tarsometatarsus lacking articular ends (WAL01.2001) from Walbeck near Helmstedt, Germany (middle Paleocene, MP5: 61.7–58.7Ma; Mayr [2007](https://doi.org/10.1671/0272-4634(2007)27[394:TBFTPF]2.0.CO;2), [2009](https://doi.org/10.1007/978-3-540-89628-9)).

- †_Eostrix tsaganica_ [Kurochkin & Dyke 2011](https://doi.org/10.1134/S003103011104006X) – distal tarsometatarsus (PIN 3104/129) from the Bumban member of the Naranbulag Formation at Tsagaan Khushuu (55.7–54.97Ma) Mongolia, assigned to †Protostrigidae ([Kurochkin & Dyke 2011](https://doi.org/10.1134/S003103011104006X)).

- cf. Selenornithidae – distal left tibiotarsus (DPC 24780) from the Jebel Qatrani Formation (Oligocene: 30.2–29.5Ma), Fayum, Egypt ([Smith et al. 2020](https://doi.org/10.3390/d12040163)).

- †_Archaehierax sylvestris_ [Mather, Lee, Camens, & Worthy, 2022](https://doi.org/10.1080/08912963.2021.1966777) – multiple bones (SAMA P.54998) from Site 12a, Lake Pinpa, Frome Downs Station, Callabonna Sub-Basin, S.A. Dolomite bed of Namba Formation, Pinpa LF, late Oligocene (26–24Ma), assigned to Accipitridae ([Mather et al. 2022](https://doi.org/10.1080/08912963.2021.1966777)).

- Accipitridae indet. – tibiotarsus (MNZ S4281) and ulna (MNZS42490) from Bannockburn Formation, St Bathans Fauna (18.26–15.97Ma), Otago, New Zealand ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957)).

- Strigidae indet. – unspecified material, presumably in the MACN, from the Pinturas Formation (19–14Ma), Santa Cruz, Argentina ([Chiappe 1991](https://doi.org/10.1080/02724634.1991.10011425)).

- Remains of _Asio madagascariensis_ ([Smith, 1834](https://www.doi.org/10.21504/saqj.s2n4p1.2852)) including DLC 17170, 17255, 17300, 18043, 18100, 18103, 18888, 18973; _Otus rutilus_ ([Pucheran, 1849](https://www.biodiversitylibrary.org/item/19604#page/35/mode/1up)) including DLC 18042, 18945, 18973; and _Ninox superciliaris_ ([Vieillot, 1817](https://www.biodiversitylibrary.org/item/60105#page/41/mode/1up)) including DLC 18103, 18946; from Ankilitelo Cave (0.013–0.005Ma), Madagascar ([Goodman et al. 2013](https://doi.org/10.11646/zootaxa.3750.5.6)).

**Minimum age:** 58.8Ma\
**Minimum justification:** The oldest taxon, †_Ogygoptynx wetmorei_, is from the _Plesiadapis churchilli_ biozone, Chron C26r: 58.8–59.5Ma ([Secord et al. 2006](https://doi.org/10.2475/ajs.306.4.211)).\
**Maximum age:** 74.43Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of taxa from Accipitrimorphae + Strigiformes on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 50.540, ξ = 51.049, ω = 6.467, α = 24.212, and ν = 2.615.

---

**CAL095:** Psittacopasseres | 54.6–81.0Ma\
**Tree mapping:** ROADIES node 603; ASTRAL node 1090\
**Node calibrated:** Last common ancestor of clade encompassing Psittaciformes (_Ara ararauna_) and Passeriformes (_Passer domesticus_).\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Morsoravis sedilis_ [Bertelli, Lindow, Dyke, & Chiappe, 2010](https://doi.org/10.1111/j.1475-4983.2010.00950.x) – articulated skeleton including the skull, vertebral column, pelvic girdle and hind limbs (Geological Museum, University of Copenhagen 28930) from the Fur Formation (55.8–54.6Ma), Denmark. Initial cladistic analysis placed †_Morsoravis_ in Charadriiformes ([Bertelli et al. 2010](https://doi.org/10.1111/j.1475-4983.2010.00950.x)), but a reexamination of the specimen and a more complete matrix placed it on the stem of Passeriformes ([Mayr 2015c](https://doi.org/10.1111/zsc.12128)). This result was replicated by a second matrix (modified from [Ksepka et al. 2017](https://doi.org/10.1073/pnas.1700188114)) of 34 species representing major clades of Telluraves, 28 fossil taxa and 146 morphological characters ([Ksepka et al. 2019](https://doi.org/10.1016/j.cub.2018.12.040)).

- †_Eozygodactylus americanus_ [Weidig, 2010](https://doi.org/10.3853/j.0067-1975.62.2010.1544) – two partial articulated skeletons (USNM 299821, WDC-CGR-014) from the Fossil Butte Member of the Green River Formation (early Eocene: 52Ma). Attributed to †Zygodactylidae, showing derived characters shared with †_Zygodactylus_ and †_Primozygodactylus_ ([Weidig 2010](https://doi.org/10.3853/j.0067-1975.62.2010.1544)). Cladistic analysis did not support monophyly of †Zygodactylidae _per se,_ but placed these zygodactyl genera on the stem lineage of Passeriformes ([Ksepka et al. 2019](https://doi.org/10.1016/j.cub.2018.12.040)).

- †_Namapsitta praeruptorum_ [Mourer-Chauviré, Pickford, & Senut, 2015](https://doi.org/10.1007%2Fs10336-014-1124-y) – distal tarsometatarsus and ulna (GSN EC 8-01′13, 8-02′13) from Eocliff (middle Eocene: 40.4–37.2Ma), Namibia, attributed to Psittaciformes _incertae sedis_ ([Mourer-Chauvire et al. 2015](https://doi.org/10.1007%2Fs10336-014-1124-y)).

- †_Nelepsittacus minimus_ [Worthy, Tennyson, & Scofield, 2011b](https://doi.org/10.1080/02724634.2011.595857) – isolated long bones (NMNZ S.42671, S.43916, S.43993–4, S.43997, S.50171, S.50870, S.51690, S.51801, S.52115, S.52163, S.52223, S.52404, S.52484, S.52683) from the Bannockburn Formation, St Bathans Fauna (early Miocene: 19–16Ma), Otago, New Zealand. Family assignment (Nestoridae) based on putative apomorphies ([Worthy et al. 2011b](https://doi.org/10.1080/02724634.2011.595857)).

- †_Orthonyx kaldowinyeri_ [Boles, 1993](https://doi.org/10.1071/MU9930044) – distal right tarsometatarsus (QM F30244) from Neville’s Garden Site, Faunal Zones A at Hiatus Site (18.5–17.5Ma; [Woodhead et al. 2016](https://doi.org/10.1016/j.gr.2014.10.004)), Riversleigh, Australia ([Nguyen et al. 2014](https://doi.org/10.1080/03115518.2014.861732)).

- cf. Tyrannidae – distal humerus (MACN-SC-1411) from the middle levels of the Pinturas Formation at “Portezuelo Sumich Sur,” Santa Cruz, Argentina ([Noriega & Chiappe 1993](https://doi.org/10.2307/4088653)). Portezuelo Sumich Sur has not been dated but sits on top of tephra samples that were dated at 16.8Ma at Portezuelo Sumich North, which exposes deeper levels of the formation ([Kramarz & Bellosi 2005](https://doi.org/10.1016/j.jsames.2004.10.005), [Fleagel et al. 2012](https://doi.org/10.1017/CBO9780511667381.003)), thus we use that date as a maximum bound for the fossil. 40Ar/39Ar dates obtained from the top of the middle level yielded an age of 16.5Ma ([Kramarz & Bellosi 2005](https://doi.org/10.1016/j.jsames.2004.10.005)), providing a minimum bound as well.

- Corvoidea indet. – partial skeleton impression (TRPM 667-011) from the Fuganji member of the Iwami formation (16.0–17.6Ma; [Hirao et al. 2005](https://www.researchgate.net/publication/257922534_Stratigraphy_and_fossil_fishes_of_the_Fuganji_Formation_at_Miyanoshita_Kokufu-cho_Tottori_Japan)) Japan ([Kakegawa & Hirao 2003](https://gbank.gsj.jp/geolis/geolis_link/200424147/en)).

- Remains of _Phedina borbonica_ ([Gmelin, 1789](https://www.biodiversitylibrary.org/item/83107#page/523/mode/1up)) including DLC 18103; _Corvus albus_ [Müller, 1776](https://www.biodiversitylibrary.org/item/218386#page/105/mode/1up) including DLC 17187D, 17189, 17216, 17246, 17265, 17268, 17272, 17298, 17300, 18099, 18102, 18103, 18105, 18157, 18758, 18876, 18906, 18909, 18921, 18944, 18946; and unspecified _Ploceus sakalava_ [Hartlaub, 1861](https://www.biodiversitylibrary.org/page/15140643#page/70/mode/1up) specimens from Ankilitelo Cave (0.0112–0.005Ma) Madagascar ([Goodman et al. 2013](https://doi.org/10.11646/zootaxa.3750.5.6)).

**Minimum age:** 54.6Ma\
**Minimum justification:** Based on the oldest taxon †_Morsoravis sedilis_ from the bottom of the Fur Formation, which was deposited during the recovery phase of the Paleocene-Eocene Thermal Maximum around 55.8Ma ago ([Stokke et al. 2020a](https://doi.org/10.30909/vol.03.02.227250)). Basalts at the top of the Formation correlate with “subphase 2b” of pyroclastic deposition in the Balder Formation suggesting a minimum age of 54.6Ma ([Stokke et al. 2020b](https://doi.org/10.1016/j.epsl.2020.116388)).\
**Maximum age:** 81.04Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Psittacopasseres on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Derived from Lowi-Merri et al. ([2024](https://doi.org/10.1080/14772019.2024.2356086)). This constraint has raised informal discussion, as the fossil was described originally as an ancient shorebird, but the most recent total-evidence phylogenetic analyses place †_Morsoravis_ on the stem of Passeriformes. The CladeDate calibration function results in a skew-Student distribution with ξ = 55.151, ω = 6.290, α = 38.217, and ν = 2.216.

---

**CAL096:** Eupasseres | 30.2–45.7Ma\
**Tree mapping:** ROADIES node 605; ASTRAL node 1098\
**Node calibrated:** Last common ancestor of clade encompassing Tyranni (_Willisornis vidua_) and Passeri (_Passer domesticus_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Wieslochia weissi_ [Mayr & Manegold, 2006](https://www.app.pan.pl/article/item/app51-315.html) – dissociated nearly complete skeleton preserved in two slabs (SMF Av 497 and SMNK–PAL.3980) from the Rauenberg clay pits (early Oligocene, Rupelian: 32–30.2Ma) near Frauenweiler, south of Wiesloch, Baden−Württemberg, Germany. Phylogenetic analysis supported the position of †_Wieslochia_ as a crown Eupasseres and within Tyranni ([Lowi-Merri et al. 2024](https://doi.org/10.1080/14772019.2024.2356086)).
 
- †_Orthonyx kaldowinyeri_ [Boles, 1993](https://doi.org/10.1071/MU9930044) – distal right tarsometatarsus (QM F30244) from Neville’s Garden Site, Faunal Zones A at Hiatus Site (18.5–17.5Ma; [Woodhead et al. 2016](https://doi.org/10.1016/j.gr.2014.10.004)), Riversleigh, Australia ([Nguyen et al. 2014](https://doi.org/10.1080/03115518.2014.861732)).

- Artamidae indet. – proximal scapula fragment (NMNZ S41061) from the Bannockburn Formation (early Miocene, Altonian: 18.26–15.97Ma) of Otago, New Zealand ([Worthy et al. 2007](https://doi.org/10.1017/S1477201906001957)).

- Corvides indet. – partial skeleton impression from the Fuganji Member of the Iwami Formation (17.6–16.0Ma; [Micklich et al. 2017](https://doi.org/10.1007/s12542-017-0340-1)), Miyanoshita, Japan ([Kakegawa & Hirao 2003](https://gbank.gsj.jp/geolis/geolis_link/200424147/en)).

- Passeriformes indet. – fragmentary distal humerus (Kenyan National Museum-SO 5466) from the Early Miocene (23.04–15.99Ma) of Songhor, Kenya ([Mayr 2014](https://doi.org/10.1016/j.geobios.2014.03.001)).

- †_Miocitta galbreathi_ [Brodkorb, 1972](https://doi.org/10.2307/1366596) – humerus (SIU P198) from the middle Miocene (Barstovian: 14.78–14.07Ma) Pawnee Creek Formation in Logan County, Colorado, USA.

- cf. Tyrannidae – distal humerus (MACN-SC-1411) from the middle levels of the Pinturas Formation at “Portezuelo Sumich Sur,” Santa Cruz, Argentina ([Noriega & Chiappe 1993](https://doi.org/10.2307/4088653)). Argon radiometric dates and tephrochronology suggest an age bounded between 16.8–16.5Ma for the middle levels of the Formation ([Kramarz & Bellosi 2005](https://doi.org/10.1016/j.jsames.2004.10.005), [Fleagel et al. 2012](https://doi.org/10.1017/CBO9780511667381.003)). 

- Remains of _Phedina borbonica_ ([Gmelin, 1789](https://www.biodiversitylibrary.org/item/83107#page/523/mode/1up)) including DLC 18103; _Corvus albus_ [Müller, 1776](https://www.biodiversitylibrary.org/item/218386#page/105/mode/1up) including DLC 17187D, 17189, 17216, 17246, 17265, 17268, 17272, 17298, 17300, 18099, 18102, 18103, 18105, 18157, 18758, 18876, 18906, 18909, 18921, 18944, 18946; and unspecified _Ploceus sakalava_ [Hartlaub, 1861](https://www.biodiversitylibrary.org/page/15140643#page/70/mode/1up) specimens from Ankilitelo Cave (0.0112–0.005Ma) Madagascar ([Goodman et al. 2013](https://doi.org/10.11646/zootaxa.3750.5.6)).

**Minimum age:** 30.2Ma\
**Minimum justification:** Based on the oldest taxon †_Wieslochia_. Biostratigraphic correlations of calcareous nannofossils and dinoflagellate cysts place the youngest Hochberg Member present in Rauenberg in the intersection of NP23 and Subzone D14a ([Maxwell et al. 2016](https://doi.org/10.1016/j.palaeo.2016.10.002)), indicating an age of 30.2–32.0Ma ([Speijer et al. 2020](https://doi.org/10.1016/B978-0-12-824360-2.00028-0)).\
**Maximum age:** 45.73Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Eupasseres on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 30.233, ξ = 30.841, ω = 4.250, α = 12.623, and ν = 2.737.

---

**CAL097:** Passerellidae and allies | 7.5–32.9Ma\
**Tree mapping:** ROADIES node 612; ASTRAL node 1122\
**Node calibrated:** Last common ancestor of clade encompassing Passerellidae (_Zonotrichia albicollis_) and Icteridae (_Agelaius phoeniceus_) + Parulidae (_Geothlypis trichas_)\
**Fossil taxon:** We surveyed the following specimens to calibrate this node:

- †_Palaeostruthus hatcheri_ ([Shufeldt, 1913](http://hdl.handle.net/2246/1412)) – rostrum maxillae (USNM 6647) collected from "Quarry E" near Long Island in Phillips County, Kansas, USA ([Steadman 1981](https://doi.org/10.1080/02724634.1981.10011889)). The rostrum shows the typical morphology of Passerellidae, distinguishable from similar groups such as Emberizidae and Calcariidae ([Steadman 1981](https://doi.org/10.1080/02724634.1981.10011889); [Oliveros et al. 2019](https://doi.org/10.1073/pnas.1813206116)). Although previously considered to be in the extant genus _Ammodramus_ ([Steadman 1981](https://doi.org/10.1080/02724634.1981.10011889)), a phylogenetic analysis is lacking, and affinities within the family may be better considered uncertain ([Stiller et al. 2024](https://www.nature.com/articles/s41586-024-07323-1)).

- †_Zonotrichia robusta_ [Tonni, 1970](https://naturalis.fcnym.unlp.edu.ar/handle/628872547/48149) – fragmentary maxillary rostrum and mandible (MLP 63-VI-30-6) from the Miramar Formation SW of Punta Armengo, Buenos Aires Province, Argentina. Magnetostratigraphic analysis indicated that the Miramar formation was deposited between 0.773–1.78Ma ([Bidegain & Rico 2011](https://doi.org/10.1016/j.quaint.2011.08.018)).

**Minimum age:** 7.5Ma\
**Minimum justification:** The oldest taxon, †_Palaeostruthus_, is from the Barstovian–Hemphillian (Miocene-Pliocene) Ogallala Formation. The deposits at Long Island Quarry E are early Hemphillian (Hh1, late Miocene; [Janis et al. 2008](https://doi.org/10.1017/CBO9780511541438)). This gives an estimated age of 9.0–7.5Ma for the fossil, based on the Hh1 boundaries given by Hilgen et al. ([2012](https://doi.org/10.1016/B978-0-444-59425-9.00029-9)).\
**Maximum age:** 32.9Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution generated by CladeDate.\
**Discussion:** Modified from Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)) and Oliveros et al. ([2019](https://doi.org/10.1073/pnas.1813206116)), this fossil has not been included in an explicit phylogenetic analysis, and therefore does not satisfy all criteria of Parham et al. ([2012](https://doi.org/10.1093/sysbio/syr107)). However, expert appraisal (DJF and DTK, _pers. comm._) during the preparation of Oliveros et al. ([2019](https://doi.org/10.1073/pnas.1813206116)) found numerous apparent synapomorphies supporting referral to at least a broader emberizoid subclade including Passerellidae. As a consequence, we treat it as a provisionally appropriate calibration for this node. The CladeDate calibration function results in a skew-Student function with ξ = 7.917, ω = 3.729, α = 18.566, and ν = 1.421.

---

### ASTRAL-only calibration

**CAL094:** Coraciimorphae | 62.2–91.9Ma\
**Tree mapping:** ROADIES: not applied; ASTRAL node 1077\
**Node calibrated:** Last common ancestor of clade encompassing Coliiformes (_Colius striatus_) and Coraciiformes (_Merops nubicus_)\
**Fossil taxa:** We surveyed the following specimens to calibrate this node:

- †_Tsidiiyazhi abini_ [Ksepka, Stidham, & Williamson, 2017](https://doi.org/10.1073/pnas.1700188114) – associated partial skeleton (NMMNH P-54128) from NMMNH locality L-6898 in the Ojo Encino Member of the Nacimiento Formation (62.52–62.22Ma), New Mexico, USA ([Ksepka et al. 2017](https://doi.org/10.1073/pnas.1700188114)).

- †_Septentrogon madseni_ [Kristoffersen, 2002](https://doi.org/10.1671/0272-4634(2001)022[0661:AEPTAT]2.0.CO;2) – fragmentary cranium without rostrum or palatines (MGUH VP 3496) from levels containing ash layers +25 through +30 in the Silstrup Mb. (55.4Ma; see [Westerhold et al. 2009](https://doi.org/10.1016/j.epsl.2009.08.027) and [Stokke et al. 2020a](https://doi.org/10.30909/vol.03.02.227250), along with discussion in [Stiller et al. 2024](https://www.nature.com/articles/s41586-024-07323-1)), Fur Formation, Denmark ([Kristoffersen 2002](https://doi.org/10.1671/0272-4634(2001)022[0661:AEPTAT]2.0.CO;2)).

- †_Ueekenkcoracias tambussiae_ [Degrange, Pol, Puerta, & Wilf, 2021](https://doi.org/10.1038/s41598-020-80479-8) – incomplete right hind limb, preserved in two slabs as part and counterpart (MPEF-PV 10991) from the Huitrera Formation at Laguna del Hunco, quarry LH27 (52.2Ma) Chubut province, Argentina ([Degrange et al. 2021](https://doi.org/10.1038/s41598-020-80479-8)).

- †_Foshanornis songi_ [Zhao, Mayr, Wang, & Wang, 2015](https://doi.org/10.1080/03115518.2015.994160) – semiarticulated nearly complete skeleton (IVPP V18855a,b) from the Buxin Formation (55.8–48.6Ma), China ([Zhao et al. 2015](https://doi.org/10.1080/03115518.2015.994160)).

- Coliidae indet. – fragmented distal tarsometatarsus (GT 120’06) from Grillental (20Ma), Northern Sperrgebiet, Namibia ([Mourer-Chauviré 2008](https://www.researchgate.net/publication/285787143_Birds_Aves_from_the_Early_Miocene_of_the_Northern_Sperrgebiet_Namibia)). 

- Halcyonidae indet. – complete carpometacarpus (QMF 29719) from Last Minute Site, Faunal Zone C (16–11.6Ma), Riversleigh, Australia, differing from all modern halcyonid genera examined including _Halcyon_ ([Boles 1997](https://publications.australian.museum/a-kingfisher-halcyonidae-from-the-miocene-of-riversleigh-northwestern-queensland-with-comments-on-the-evolution-of-kingfishers-in-australo-papua/)).

- _Leptosomus discolor_ ([Hermann, 1783](https://www.biodiversitylibrary.org/item/120418#page/206/mode/1up)) – remains (DLC 18042) from Ankilitelo Cave (0.013–0.005Ma), Madagascar ([Goodman et al. 2013](https://doi.org/10.11646/zootaxa.3750.5.6)).

- _Halcyon sancta_ [Vigors & Horsfield, 1827](https://www.biodiversitylibrary.org/item/13694#page/212/mode/1up) – two right humeri (accessions not specified) from the Holocene of Gilles Cave (0.0036–0.0032Ma), New Caledonia ([Balouet & Olson 1989](http://dx.doi.org/10.5479/si.00810282.469))

**Minimum age:** 62.2Ma\
**Minimum justification:** The oldest of these taxa, †_Tsidiiyazhi abini_, is from NMMNH locality L-6898, which was located within magnetochron C27N, constraining the absolute age to between 62.221 and 62.517Ma ([Ksepka et al. 2017](https://doi.org/10.1073/pnas.1700188114)).\
**Maximum age:** 91.89Ma\
**Maximum justification:** Based on the 95% quantile of the empirical calibration distribution using first fossil occurrences of Coraciimorphae on each continent and the CladeDate algorithm ([Claramunt 2022](https://besjournals.onlinelibrary.wiley.com/doi/abs/10.1111/2041-210X.13977)).\
**Discussion:** Based on Stiller et al. ([2024](https://www.nature.com/articles/s41586-024-07323-1)), the CladeDate calibration function results in an offset skew-Student distribution with offset = 62.240, ξ = 62.334, ω = 7.442, α = 137.954, and ν = 2.258. This group does not form a clade in the ROADIES v0.0.0 tree for **Node 600** (instead, it resolves to **Node 599**), but is recovered in the newer analyses such as ASTRAL v0.1.1. This calibration is therefore omitted from ROADIES and applied only to ASTRAL.

---

## References

Agnolin, F.L., Tomassini, R.L. and Contreras, V.H., 2016, January. Oldest record of thinocoridae (aves, Charadriiformes) from south America. In Annales de paleontologie (Vol. 102, No. 1, pp. 1-6). Elsevier Masson.

Alvarenga, H.M., 1999. A Fossil Screamer (Anseriformes: Anhimidae) from the Middle Tertiary of Southeastern Brazil. Smithsonian Contributions to Paleobiology, (89) 223-230.

Andrews, C.W. 1897. On some fossil remains of Carinate birds from Central Madagascar. Ibis 39(3): 343–359.

Balouet, J. C., & S. L. Olson 1989 Fossil birds from late Quaternary deposits in New Caledonia. Smithsonian Contributions to Zoology 469:1-38.

Berggren, W.A., Kent, D.V., Swisher, C.C., and Aubrey, M.-P. 1995. A revised Cenozoic geochronology and chronostratigraphy. In Geochronology, Time Scales and Global Stratigraphic Correlation, ed. W.A. Berggren, D.V. Kent, M.-P. Aubry, and J. Hardenbol. Society of Economic Paleontologists and Mineralogists Special Publication 54: 129–212.

Bertelli, S., B. E. Lindow, G. J. Dyke & L. M. Chiappe 2010. A well-preserved ‘charadriiform-like’ fossil bird from the Early Eocene Fur Formation of Denmark. Palaeontology 53:507–531.

Bertelli, S., L. M. Chiappe & G. Mayr. 2011. A new Messel rail from the Early Eocene Fur Formation of Denmark (Aves, Messelornithidae). Journal of Systematic Palaeontology 9.4: 551-562. 

Bidegain, J. C., & Rico, Y. (2012). Magnetostratigraphy and magnetic parameters of a sedimentary sequence in Punta San Andres, Buenos Aires, Argentina. Quaternary International, 253, 91-103.

Blokland, J. C., C. M. Reid, T. H. Worthy, A. J. D. Tennyson, J. A. Clarke, & R. P. Scofield. 2019. Chatham Island Paleocene fossils provide insight into the palaeobiology, evolution, and diversity of early penguins (Aves, Sphenisciformes). Palaeontologia Electronica 22 (3):78.

Boast, A.P., Chapman, B., Herrera, M.B., Worthy, T.H., Scofield, R.P., Tennyson, A.J., Houde, P., Bunce, M., Cooper, A. and Mitchell, K.J., 2019. Mitochondrial Genomes from New Zealand’s Extinct Adzebills (Aves: Aptornithidae: Aptornis) Support a Sister-Taxon Relationship with the Afro-Madagascan Sarothruridae. Diversity, 11(2), p.24.

Boles, W. E. 1993. A logrunner Orthonyx (Passeriformes, Orthonychidae) from the Miocene of Riversleigh, north-western Queensland. Emu, 93(1), 44-49.

Boles, W. E., 1997. A kingfisher (Halcyonidae) from the Miocene of Riversleigh, northwestern Queensland, with comments on the evolution of kingfishers in Australo-Papua. Memoirs of the Queensland Museum 41:229-234.

Boles, W. E., 2001. A swiftlet (Apodidae: Collocaliini) from the Miocene of Riversleigh, northwestern Queensland. Memoir of the Association of Australasian Palaeontologists 25: 45–52.

Boles, W.E., 2005. A new flightless gallinule (Aves: Rallidae: Gallinula) from the Oligo-Miocene of Riversleigh, northwestern Queensland, Australia. Records of the Australian Museum 57(2), p.179.

Bourdon, E., B. Bouya & M. Iarchene 2005. Earliest African Neornithine Bird: A New Species of Prophaethontidae (Aves) from the Paleocene of Morocco. J. Vert. Paleontol. 25:157-170.

Bourdon, E., C. Mourer-Chauviré, M. Amaghzaz & B. Bouya 2008. New specimens of Lithoptila abdounensis (Aves, Prophaethontidae) from the lower Paleogene of Morocco. J. Vert. Paleontol. 28: 751-761.

Bowman, V., J. Ineson, J. Riding, J. Crame, J. Francis, D. Condon, R. Whittle & F. Ferraccioli. 2016. The Paleocene of Antarctica: Dinoflagellate cyst biostratigraphy, chronostratigraphy and implications for the palaeo-Pacific margin of Gondwana. Gondwana Research 38:132-148.

Braun, E.L., Cracraft, J. and Houde, P., 2019. Resolving the avian tree of life from top to bottom: the promise and potential boundaries of the phylogenomic era. In Avian genomics in ecology and evolution: from the lab into the wild (pp. 151-210). Cham: Springer International Publishing.

Brodkorb, P. 1972. Neogene fossil jays from the Great Plains. Condor 347-349.

Chandler, R., 1999. Fossil birds of Florissant, Colorado: with a description of a new genus and species of cuckoo. Geologic Resources Division, Technical Report, NPS/NRGRD/ GRDTR-99, 49-53.

Chen, A., N. D. White, R. B. J. Benson, M. J. Braun & D. J. Field. 2019. Total-evidence framework reveals complex morphological evolution in nightbirds (Strisores). Diversity 11(9):143.

Chiappe, L. M. 1991. Fossil birds from the Miocene Pinturas Formation of Southern Argentina. Journal of Vertebrate Paleontology 11, 21A–22A.

Claramunt, S., 2022. CladeDate: Calibration information generator for divergence time estimation. Methods in Ecology and Evolution, 13(11), pp.2331-2338.

Coster, P., Benammi, M., Mahboubi, M., Tabuce, R., Adaci, M., Marivaux, L., Bensalah, M., Mahboubi, S., Mahboubi, A., Mebrouk, F. & Maameri, C. 2012. Chronology of the Eocene continental deposits of Africa: Magnetostratigraphy and biostratigraphy of the El Kohol and Glib Zegdou Formations, Algeria. Geological Society of America Bulletin 124(9-10):1590-1606.

De Pietri, V.L., Berger, J.P., Pirkenseer, C., Scherler, L. and Mayr, G., 2009. New skeleton from the early Oligocene of Germany indicates a stem-group position of diomedeoidid birds. Acta Palaeontologica Polonica, 55(1), pp.23-34.

De Pietri, V. L., Camens, A. B., & Worthy, T. H. (2015). A Plains‐wanderer (Pedionomidae) that did not wander plains: a new species from the Oligocene of South Australia. Ibis, 157(1), 68-74.

De Pietri, V. L., Scofield, R. P., Tennyson, A. J., Hand, S. J., & Worthy, T. H. (2016). Wading a lost southern connection: Miocene fossils from New Zealand reveal a new lineage of shorebirds (Charadriiformes) linking Gondwanan avifaunas. Journal of Systematic Palaeontology, 14(7), 603-616.

Elzanowski A, Boles WE. 2012 Australia’s oldest Anseriform fossil: a quadrate from the Early Eocene Tingamarra Fauna. Palaeontology 55, 903–911.

Field, D.J. & Hsiang, A.Y. (2018): A North American stem turaco, and the complex biogeographic history of modern birds. BMC Evolutionary Biology 18 (102), pp 1–16.

Field, D. J., J. Benito, A. Chen, J. W. M. Jagt, & D. T. Ksepka 2020. Late Cretaceous neornithine from Europe illuminates the origins of crown birds. Nature 579 (7799): 397–401.

Fleagle, J.G., Perkins, M.E., Heizler, M.T., Nash, B., Bown, T.M., Tauber, A.A., Dozo, M.T. & M. F. Tejedor 2012. Tephrochronology of the Miocene Santa Cruz and Pinturas formations, Argentina. In: Vizcaíno, S.F., Kay, R.F., Bargo, M.S. (Eds.), Early Miocene Paleobiology in Patagonia: High-latitude Paleocommunities of the Santa Cruz Formation. Cambridge University Press.

Goodman, S.M. 1999. Holocene bird subfossils from the sites of Ampasambazimba, Antsirabe and Ampoza, Madagascar: Changes in the avifauna of south-central Madagascar over the past few millennia. In: Adams, N.J. & Slotow, R.H. (eds) Proc. 22 Int. Ornithol. Congr., Durban: 3071-3083. Johannesburg: BirdLife South Africa.

Goodman, S. M., M. J. Raherilalao & K. Muldoon 2013. Bird fossils from Ankilitelo Cave: inference about Holocene environmental changes in Southwestern Madagascar. Zootaxa 3750(5):534-548.

Gmelin, J. F. 1789. Caroli a Linné, systema naturae. Tom. I. Pars II. – pp. 501–1032. Lipsiae. (Beer)

Guérin, C, M. A. Curvello, M. Faure, M. Hugueney & C. Mourer-Chauviré 1996 The Pleistocene fauna of Piauí (Northeastern Brazil): paleochronological and biochronological implications. Proceedings of the International Meeting on the Peopling of the Americas, São Raimundo Nonato, Piauí, Brasil (1993). Fundamentos 1(1):55-103.

Guilday, J. E., P. W. Parmalee, and H. W. Hamilton. 1977. The Clark's Cave bone deposit and the Late Pleistocene paleoecology of the central Appalachian Mountains of Virginia. Bulletin of Carnegie Museum of Natural History 2:1-87.

Harrison, C. J. O.  1984. A revision of the fossil swifts (Vertebrata, Aves, suborder, Apodi), with descriptions of three new genera and two new species. Mededelingen van de Werkgroep voor Tertiaire en Kwartaire Geologie 21(4):157-177.

Hartlaub, G. 1861. Ornithologischer Beitrag zur Fauna Madagaskar’s. Bremen: C. Schünemann, p. 54.

Heingård, M., Musser, G., Hall, S. A., & Clarke, J. A. (2021). New remains of Scandiavis mikkelseni inform avian phylogenetic relationships and brain evolution. Diversity, 13(12), 651.

Hermann, J. 1783. Tabula affinitatum animalium. Strasbourg: J.G. Treuttel. p. 186.

Hesse, A. 1992. A new species of Messelornis (Aves: Gruiformes: Messelornithidae) from the Middle Eocene Green River Formation. Papers in Avian Paleontology honoring Pierce Brodkorb.-Los Angeles County Museum of Natural History, Science Series, 36, 171-178.

Hilgen, F. J., Lourens, L. J., & Van Dam, J. A. 2012. The Neogene Period. In F. M. Gradstein, J. G. Ogg, M. D. Schmitz, & G. M. Ogg (eds.), The Geologic Time Scale 2012, vol. 2, pp. 923–978. Elsevier, Amsterdam.

Hirao, K., Yano, T., Uyeno, T., Yabumoto, Y., & Aoki, T. (2005). Stratigraphy and fossil fishes of the Fuganji Formation at Miyanoshita, Kokufu-cho, Tottori, Japan. Bull. Tottori Pref. Mus, 42, 3-20.

Hoch, E. 1997. Notes on palaeornithology and on a New Bird from the Early Tertiary North Sea Region. Geological Society of Denmark, Online Series 1.

Hood, S. C., C. R. Torres, M. A. Norell and J. A. Clarke. 2019. New fossil birds from the earliest Eocene of Mongolia. American Museum Novitates 3934:1-22.

Hou, L.H. 1990 An Eocene bird from Songzi, Hubei province. Vertebr. Palasiat. 28:34-42. [In Chinese]

Houde, P., Dickson, M., & Camarena, D. (2023). Basal anseriformes from the early Paleogene of North America and Europe. Diversity, 15(2), 233.

Howard, H. 1992. New records of middle Miocene anseriform birds from Kern County, California. Papers in Avian Paleontology Honoring Pierce Brodkorb. Natural History Museum of Los Angeles County, Science Series, 36, 231-237

Janis, C.M., Gunnell, G.F., & Uhen, M.D., eds. 2008. Evolution of Tertiary Mammals of North America. Cambridge University Press.

Jenkins, R. J. F. 1974. A new giant penguin from the Eocene of Australia. Palaeontology, 17, 2, 291–310.

Kakegawa, Y. & K. Hirao 2003 A Miocene passeriform bird from the Iwami Formation, Tottori Group, Tottori, Japan. Bulletin of the National Science Museum, Series C 29:33–37.

King, C. 2016. A revised correlation of Tertiary rocks in the British Isles and adjacent areas of NW Europe. Geol. Soc. Lond. Spec. Rep. 27: 1–719.

Kramarz, A. G., & E. S. Bellosi 2005. Hystricognath rodents from the Pinturas Formation, Early–Middle Miocene of Patagonia, biostratigraphic and paleoenvironmental implications. Journal of South American Earth Sciences 18(2):199-212.

Ksepka, D. T., & J. A. Clarke. 2012. The basal penguin (Aves: Sphenisciformes) Perudyptes devriesi and a phylogenetic evaluation of the penguin fossil record. Bulletin of the American Museum of Natural History 337:1-77.

Ksepka, D.T. and Thomas, D.B., 2012. Multiple cenozoic invasions of Africa by penguins (Aves, Sphenisciformes). Proceedings of the Royal Society B: Biological Sciences, 279(1730), pp.1027-1032.

Ksepka, D. T., S. Bertelli & N. P. Giannini. 2006. The phylogeny of the living and fossil Sphenisciformes (penguins). Cladistics 22(5): 412-441.

Ksepka, D. T., J. A. Clarke, S. J. Nesbitt, F. B. Kulp & L. Grande. 2013. Fossil evidence of wing shape in a stem relative of swifts and hummingbirds (Aves, Pan-Apodiformes). Proc. R. Soc. B 280: 20130580.

Ksepka, D. T., T. A. Stidham & T. E. Williamson. 2017 Early Paleocene landbird supports rapid phylogenetic and morphological diversification of crown birds after the K–Pg mass extinction. Proceedings of the National Academy of Sciences 114(30):8047-8052.

Ksepka, D.T., L. Grande & G. Mayr 2019. Oldest finch-beaked birds reveal parallel ecological radiations in the earliest evolution of passerines. Current Biology 29(4):657-663.

Kurochkin, E. N. 1976. A survey of the Paleogene birds of Asia. Smithson. Contrib. Paleobiol. 27:75-86.

Kurochkin E. N. & A. A. Dyke 2009. A large collection of Presbyornis (Aves, Anseriformes, Presbyornithidae) from the late Paleocene and early Eocene of Mongolia. Geological Journal 45:375-387.

Linnaeus, C. 1758. Systema Naturae, 10th edition, vol. 1. Stockholm: Laurentius Salvius.

Lowi-Merri, T. M., Gjevori, M., Bochenski, Z. M., Wertz, K., & Claramunt, S. (2024). Total-evidence dating and the phylogenetic affinities of early fossil passerines. Journal of Systematic Palaeontology, 22(1), 2356086.

Manegold, A., A. Louchart, J. Carrier & A. Elzanowski 2013 The early Pliocene avifauna of Langebaanweg (South Africa): a review and update. In Paleornithological Research 2013: Proceedings of the 8th International Meeting of the Society of Avian Paleontology and Evolution pp. 135-152. 

Maxwell, E.E., Alexander, S., Bechly, G., Eck, K., Frey, E., Grimm, K., Kovar-Eder, J., Mayr, G., Micklich, N., Rasser, M. and Roth-Nebelsick, A., 2016. The Rauenberg fossil Lagerstätte (Baden-Württemberg, Germany): A window into early Oligocene marine and coastal ecosystems of Central Europe. Palaeogeography, Palaeoclimatology, Palaeoecology, 463, pp.238-260.

Mayr, G. 2003 Phylogeny of early Tertiary swifts and hummingbirds (Aves: Apodiformes). Auk 120:145-151.

Mayr, G. 2006. A specimen of Eocuculus Chandler, 1999 (Aves, ?Cuculidae) from the early Oligocene of France. Geobios, 39(6), 865-872.

Mayr, G. 2007. The birds from the Paleocene fissure filling of Walbeck (Germany). Journal of Vertebrate Paleontology, 27(2), 394–408.

Mayr, G. 2009. Paleogene Fossil Birds. Berlin, Heidelberg: Springer, 262 pp.

Mayr, G., 2010. Reappraisal of Eocypselus—A stem group apodiform from the early Eocene of Northern Europe. Palaeobiodiversity and Palaeoenvironments, 90(4), pp.395-403.

Mayr, G. 2014. On the middle Miocene avifauna of Maboko Island, Kenya. Geobios, 47(3), 133-146.

Mayr, G. 2015a. New remains of the Eocene Prophaethon and the early evolution of tropicbirds (Phaethontiformes). Ibis 157(1):54-67.

Mayr, G. 2015b. A new Paleogene procellariiform bird from western North America. Neues Jahrbuch für Geologie und Paläontologie-Abhandlungen 275(1):11-17.

Mayr, G., 2015c. A reassessment of Eocene parrotlike fossils indicates a previously undetected radiation of zygodactyl stem group representatives of passerines (Passeriformes). Zoologica Scripta 44(6):587-602.

Mayr, G. 2016. The world’s smallest owl, the earliest unambiguous charadriiform bird, and other avian remains from the early Eocene Nanjemoy Formation of Virginia (USA). PalZ, 90(4), 747-763.

Mayr, G., & A. Manegold. 2006. New specimens of the earliest European passeriform bird. Acta Palaeontologica Polonica 51:315–323. 

Mayr, G., & T. Smith. 2012. Phylogenetic affinities and taxonomy of the Oligocene Diomedeoididae, and the basal divergences amongst extant procellariiform birds. Zoological Journal of the Linnean Society, 166:854-875.

Mayr, G. & R. P. Scofield. 2016. New avian remains from the Paleocene of New Zealand: the first early Cenozoic Phaethontiformes (tropicbirds) from the Southern Hemisphere. J. Vert. Paleontol.: e1031343.

Mayr, G., & Kitchener, A. C. 2023. Early Eocene fossils elucidate the evolutionary history of the Charadriiformes (shorebirds and allies). Journal of Paleontology, 97(4), 941-955.

Mayr, G. and Kitchener, A.C., 2024. New fossils of Eocypselus and Primapus from the British London Clay reveal a high taxonomic and ecological diversity of early Eocene swift‐like apodiform birds. Ibis, 166(4), pp.1199-1217.

Mayr, G., & Kitchener, A. C. 2025. Leg bones of the anseriform taxon Nettapterornis from the London Clay of Walton-on-the-Naze and notes on the bony-toothed birds from this locality. PalZ, 99(3), 355-369.

Micklich, N., Bannikov, A. F., & Yabumoto, Y. (2017). First record of ponyfishes (Perciformes: Leiognathidae) from the Oligocene of the Grube Unterfeld (“Frauenweiler”) clay pit. PalZ, 91(3), 375-398.

Milne-Edwards, A. 1863. Sur la distribution géologique des oiseaux fossiles et description de quelques espèces nouvelles. Comptes rendus hebdomadaires des séances de l'Académie des sciences 56: 1219–1222.

Mourer-Chauviré, C. 2008. Birds (Aves) from the Early Miocene of the Northern Sperrgebiet, Namibia. Geology and Palaeobiology of Namib Desert, Southwestern Africa, 20: 147-167.

Mourer-Chauvire, C., Bour, R., Ribes, S. and Moutou, F., 1999. The avifauna of Réunion Island (Mascarene Islands) at the time of the arrival of the first Europeans. Smithsonian contributions to paleobiology, 89(1999), pp.1-38.

Mourer-Chauviré, C., Pickford, M. and Senut, B., 2011. The first Palaeogene galliform from Africa. Journal of Ornithology, 152(3), pp.617-622.

Mourer-Chauviré, C., Tabuce, R., Essid, E. M., Marivaux, L., Khayati, H., Vianey-Liaud, M., & Ben Haj Ali, M. 2013. A new taxon of stem group Galliformes and the earliest record for stem group Cuculidae from the Eocene of Djebel Chambi, Tunisia. In U. B. Göhlich & A. Kroh (eds.), Paleornithological Research 2013: Proceedings of the 8th International Meeting of the Society of Avian Paleontology and Evolution, Vienna, Austria, pp. 1–15. Natural History Museum Vienna, Vienna.

Mourer-Chauvire, C., M. Pickford & B. Senut. 2015. Stem group galliform and stem group psittaciform birds (Aves, Galliformes, Paraortygidae, and Psittaciformes, family incertae sedis) from the Middle Eocene of Namibia. Journal of Ornithology 156:275-286.

Mourer-Chauviré, C., Essid, E.M., Khayati, H., Marivaux, L., Marzougui, W., Temani, R., Vianey-Liaud, M. & Tabuce, R. 2016. New remains of the very small cuckoo, Chambicuculus pusillus (Aves, Cuculiformes, Cuculidae) from the late Early or early Middle Eocene of Djebel Chambi, Tunisia. Palaeovertebrata 40(1):1-4.

Müller, P. L. S. 1776. Des Ritters Carl von Linné vollständiges Natursystem Supplement- und Registerband. Nürnberg: Gabriel Nicolaus Raspe, p. 82.

Musser, G. & J. A. Clarke 2020. An exceptionally preserved specimen from the Green River Formation elucidates complex phenotypic evolution in Gruiformes and Charadriiformes. Frontiers in Ecology and Evolution 8(326):1-18.

Musser, G., & J. A. Clarke 2024. A new Paleogene fossil and a new dataset for waterfowl (Aves: Anseriformes) clarify phylogeny, ecological evolution, and avian evolution at the K-Pg Boundary. Plos one, 19(7), e0278737.

Musser, G.M. & J. Cracraft 2019. A new morphological dataset reveals a novel relationship for the adzebills of New Zealand (Aptornis) and provides a foundation for total evidence neoavian phylogenetics. American Museum Novitates 2019(3927):1-70.

Musser G., D. T. Ksepka & D. J. Field 2019. New Material of Paleocene-Eocene Pellornis (Aves: Gruiformes) Clarifies the Pattern and Timing of the Extant Gruiform Radiation. Diversity 11(7):1-25.

Nascimento, R., & Silveira, L. F. (2020). The fossil birds of Peter Lund. Zootaxa, 4743(4), 480-510.

Nessov, L. A. 1988. New Cretaceous and Paleocene birds of Soviet Middle Asia and Kazakhstan and their environments. Trudy Zoologiceskogo Instituta Akademii Nauk SSSR 182:116–123. [In Russian]

Nessov, L. A. 1992. Mesozoic and Paleogene birds of the USSR and their paleoenvironments; pp. 465–478 in K. E. Campbell (ed.), Papers in Avian Paleontology Honoring Pierce Brodkorb. Natural History Museum of Los Angeles County, Science Series 36.

Nguyen, J. M. T., Boles, W. E., Worthy, T. H., Hand, S. J., & Archer, M. (2014). New specimens of the logrunner Orthonyx kaldowinyeri (Passeriformes: Orthonychidae) from the Oligo-Miocene of Australia. Alcheringa: An Australasian Journal of Palaeontology, 38(2), 245–255.

Noriega, J. I., & Chiappe, L. M. (1993). An early Miocene passeriform from Argentina. The Auk, 936-938.

Oliveros, C.H., Field, D.J., Ksepka, D.T., Barker, F.K., Aleixo, A., Andersen, M.J., Alström, P., Benz, B.W., Braun, E.L., Braun, M.J. and Bravo, G.A., 2019. Earth history and the passerine superradiation. Proceedings of the National Academy of Sciences, 116(16), pp.7916-7925.

Olson, S. L. 1992 A new family of primitive landbirds from the Lower Eocene Green River Formation of Wyoming. Natural History Museum of Los Angeles County Science Series 36, pp 127-136.

Olson, S. L. 1994. A giant Presbyornis (Aves, Anseriformes) and other birds from the Paleocene Aquia Formation of Maryland and Virginia. Proceedings of the Biological Society of Washington 107:429-435.

Olson, S.L., 1999. The anseriform relationships of Anatalavis Olson and Parris (Anseranatidae), with a new species from the Lower Eocene London Clay. Smithsonian Contributions to Paleobiology, 89, pp.231-243.

Pallas, P. S. 1769. Spicilegia zoologia: quibus novae imprimis et obscurae animalium species iconibus, descriptionibus atque commentariis illustrantur, Volume 1, Fasc. 5. Gottlieb August Lange, Berlin, Germany, v + 34 pp., 5 pls.

Parham, J.F., Donoghue, P.C., Bell, C.J., Calway, T.D., Head, J.J., Holroyd, P.A., Inoue, J.G., Irmis, R.B., Joyce, W.G., Ksepka, D.T. and Patané, J.S., 2012. Best practices for justifying fossil calibrations. Systematic biology, 61(2), pp.346-359.

Pucheran, J. 1849. Note sur une nouvelle espèce de hibou de Madagascar. Revue et Magasin de Zoologie Pure et Appliquée, sér. 2, 1: 29.

Rasmussen, D. T., Olson, S. L. & E. L. Simons. 1987. Fossil birds from the Oligocene Jebel Qatrani Formation, Fayum Province, Egypt. Smithsonian Contributions to Paleobiology 62:1-20.

Rich, P.V., 1980. Preliminary report on the fossil avian remains from late Tertiary sediments at Langebaanweg (Cape Province), South Africa. South African Journal of Science, 76(4), pp.166-170.

Rich, P. V., & D. J. Bohaska. 1976. The world’s oldest owl: A new strigiform from the Paleocene of southwestern Colorado. Smithson. Contrib. Paleobiol. 27, 87–93.

Secord, R., P. D. Gingerich, M. E. Smith, W. C. Clyde, P. Wilf, and B. S. Singer (2006) Geochronology and mammalian stratigraphy of middle and upper Paleocene continental strata, Bighorn Basin, Wyoming. American Journal of Science, 306: 211–245.

Seiffert, E. R. 2006 Revised Age Estimates for the Later Paleogene Mammal Faunas of Egypt and Oman. Proc. Natl. Acad. Sci. USA 103, 5000–5005.

Shaw, G. 1796. Cimelia Physica. Figures of rare and curious quadrupeds, birds, etcetera, together with several of the most elegant plants. B. & J. White, London

Shufeldt, R. W. 1913. Further studies of fossil birds with descriptions of new and extinct species. Bulletin of the American Museum of Natural History 32(16):285-306.

Shute, E., Prideaux, G.J., Worthy, T.H. 2016. Three terrestrial Pleistocene coucals (Centropus: Cuculidae) from southern Australia: biogeographical and ecological significance, Zoological Journal of the Linnean Society, 177, 964–1002.

Simpson, G.G. 1971. Fossil penguin from the late Cenozoic of South Africa. Science, 171(3976), pp.1144-1145.

Simpson, G.G. 1973. Tertiary penguins (Sphenisciformes, Spheniscidae) from Ysterplaats, Cape Town, South Africa. South African Journal of Science 69: 342–344.

Simpson, G.G. 1979a. A new genus of Late Tertiary penguin from Langebaanweg, South Africa. Annals of the South African Museum 78: 1–9.

Simpson, G.G. 1979b. Tertiary penguins from the Duinefontein site, Cape Province, South Africa. Annals of the South African Museum 79: 1–17.

Slack, K. E., C. M. Jones, T. Ando, G. L. Harrison, R. E. Fordyce, U. Arnason & D. Penny 2006. Early penguin fossils, plus mitochondrial genomes, calibrate avian evolution. Mol. Biol. Evol. 23 (6):1144-1155.

Smith, A. 1834. Descriptions of some African birds. South African Quarterly Journal 2(4, pt. 1): 315–317.

Smith, M.E., Carroll, A.R., & Singer, B.S. 2008 Synoptic reconstruction of a major ancient lake system: Eocene Green River Formation, western United States. Geological Society of America Bulletin 120 (1/2), pp 54-84.

Smith, M.E., Chamberlain, K.R., Singer, B.S. & Carroll, A.R. (2010): Eocene clocks agree: coeval 40Ar/39Ar, U-Pb, and astronomical ages from the Green River Formation. Geology 38 (6), pp 527-530.

Smith, N.A., Stidham, T.A. and Mitchell, J.S., 2020. The first fossil owl (Aves, Strigiformes) from the Paleogene of Africa. Diversity, 12(4), p.163.

Speijer, R. P., Pälike, H., Hollis, C. J., Hooker, J. J., & Ogg, J. G. 2020. The Paleogene Period. In F. M. Gradstein, J. G. Ogg, M. D. Schmitz, & G. M. Ogg (Eds.), Geologic Time Scale 2020 (pp. 1087–1140). Elsevier B.V.: Amsterdam.

Steadman, D. W. (1981). A re-examination of Palaeostruthus hatcheri (Shufeldt), a late Miocene sparrow from kansas. Journal of Vertebrate Paleontology, 1(2), 171–173.

Stiller, J., Feng, S., Chowdhury, A.A., Rivas-González, I., Duchêne, D.A., Fang, Q., Deng, Y., Kozlov, A., Stamatakis, A., Claramunt, S. and Nguyen, J.M., 2024. Complexity of avian evolution revealed by family-level genomes. Nature, 629(8013), pp.851-860.

Stokke, E. W., E. Liu & M. T. Jones 2020a. Evidence of explosive hydromagmatic eruptions during the emplacement of the North Atlantic Igneous Province. Volcanica 3(2):227-250.

Stokke, E. W., M. T. Jones, J. E. Tierney, H. H. Svensen, & J. H. Whiteside 2020b. Temperature changes across the Paleocene-Eocene Thermal Maximum – a new high-resolution TEX86 temperature record from the Eastern North Sea Basin. Earth and Planetary Science Letters 544:116388.

Tambussi C. P. 1998. Nuevo Anatidae (Aves: Anseriformes) del Plioceno de la región pampeana, Argentina. Boll. Soc Hist. Nat. Balears 41: 19-25.

Tambussi, C. P., M. A. Reguero, S. A. Marenssi, & S. N. Santillana 2005. Crossvallia unienwillia, a new Spheniscidae (Sphenisciformes, Aves) from the Late Paleocene of Antarctica. Geobios 38:667-675.

Tambussi, C.P., F.J. Degrange, R.S. De Mendoza, E. Sferco & S. Santillana. 2019. A stem anseriform from the early Palaeocene of Antarctica provides new key evidence in the early evolution of waterfowl. Zoological Journal of the Linnean Society 186(3):673-700.

Thomas, D.B. and Ksepka, D.T., 2013. A history of shifting fortunes for African penguins. Zoological Journal of the Linnean Society, 168(1), pp.207-219.

Tonni, E. P. 1970. Zonotrichia robusta n. sp. (Aves, Passeriformes) del Pleistoceno Medio de Buenos Aires. Ameghiniana 11:366-372.

van Beneden PJ 1871. Les oiseaux de l’argile rupélienne. Bulletin de l’Académie Royale des Sciences, Lettres et Beaux-Arts de Belgique, série 2 32: 256–261.

Vieillot, L. P. 1817. Nouveau Dictionnaire d’Histoire Naturelle, nouvelle édition, vol. 7. Paris: Deterville. 586 pp.

Vigors, N. A. & Horsfield, T. 1827. A description of the Australian birds in the collection of the Linnean Society; with an attempt at arranging them according to their natural affinities. Transactions of the Linnean Society of London 15(1): 170–331.

Wang, M., Mayr, G., Zhang, J. and Zhou, Z., 2012. Two new skeletons of the enigmatic, rail-like avian taxon Songzia Hou, 1990 (Songziidae) from the early Eocene of China. Alcheringa, 36(4), pp.487-499.

Watanabe, J., Matsuoka, H., & Hasegawa, Y. (2018). Pleistocene non-passeriform landbirds from Shiriya, northeast Japan. Acta Palaeontologica Polonica, 63(3).

Watanabe, J., Koizumi, A., Nakagawa, R., Takahashi, K., Tanaka, T. and Matsuoka, H., 2019. Seabirds (Aves) from the Pleistocene Kazusa and Shimosa Groups, Central Japan. Journal of Vertebrate Paleontology,39(5):e1697277.

Weidig, I., 2010. New birds from the lower Eocene Green River Formation, North America. Records of the Australian Museum, 62(1), pp.29-44.

Westerhold, T., U. Röhl, H. K. McCarren, and J. C. Zachos 2009 Latest on the absolute age of the Paleocene–Eocene Thermal Maximum (PETM): New insights from exact stratigraphic position of key ash layers 19 and -17. Earth and Planetary Science Letters 287:412–419.

Winge, O. 1887. Fugle fra Knoglehuler i Brasilien. E Museo Lundii, 1 (2), 1–54.

Woodburne, M. O., B. J. MacFadden, J. A. Case, M. S. Springer, N. S. Pledge, J. D. Power, J. M. Woodburne & K. B. Springer. 1994. Land mammal biostratigraphy and magnetostratigraphy of the Etadunna Formation (late Oligocene) of South Australia. Journal of Vertebrate Paleontology 13(4):483-515.

Woodhead, J., S. J. Hand, M. Archer, I. Graham, K. Sniderman, D. A. Arena, K. H. Black, H. Godthelp, P. Creaser & Price, E. (2016). Developing a radiometrically-dated chronologic sequence for Neogene biotic change in Australia, from the Riversleigh World Heritage Area of Queensland. Gondwana Research 29(1):153-167.

Worthy, T. H. 2009. Descriptions and phylogenetic relationships of two new genera and four new species of Oligo-Miocene waterfowl (Aves: Anatidae) from Australia. Zoological Journal of the Linnean Society 156: 411–454.

Worthy, T.H. and Lee, M.S., 2008. Affinities of Miocene waterfowl (Anatidae: Manuherikia, Dunstanetta and Miotadorna) from the St Bathans Fauna, New Zealand. Palaeontology, 51(3), pp.677-708.

Worthy, T.H. and Nguyen, J.M., 2020. An annotated checklist of the fossil birds of Australia. Transactions of the Royal Society of South Australia, 144(1), pp.66-108.

Worthy, T. H., & Boles, W. E. 2011. Australlus, a new genus for Gallinula disneyi (Aves: Rallidae) and a description of a new species from Oligo-Miocene deposits at Riversleigh, northwestern Queensland, Australia. Records of the Australian Museum, 63(1), 61-77.

Worthy, T. H., A. J. D. Tennyson, C. Jones, J. A. McNamara & B. J. Douglas. 2007. Miocene waterfowl and other birds from Central Otago, New Zealand. Journal of Systematic Palaeontology 5:1–39.

Worthy, T.H.; Tennyson, A.J.; Scofield, R.P. 2011a. Fossils reveal an early Miocene presence of the aberrant gruiform Aves: Aptornithidae in New Zealand. J. Ornithol. 152, 669–680.

Worthy, T. H., Tennyson, A. J., & Scofield, R. P. 2011b. An early Miocene diversity of parrots (Aves, Strigopidae, Nestorinae) from New Zealand. Journal of Vertebrate Paleontology, 31(5), 1102-1116.

Worthy, T.H., Scofield, R.P., Salisbury, S.W., Hand, S.J., De Pietri, V.L. and Archer, M., 2022. Two new neoavian taxa with contrasting palaeobiogeographical implications from the early Miocene St Bathans Fauna, New Zealand. Journal of Ornithology, 163(3), pp.643-658.

Zelenkov, N. V. 2011. Diving ducks from the Middle Miocene of western Mongolia. Paleontological Journal, 45(2), 191-199.

Zelenkov, N.V. 2012. A new duck from the Middle Miocene of Mongolia, with comments on Miocene evolution of ducks. Paleontol. J. 46: 520–530.
