# Crocodylia calibrations

One terminal node (**731:** Crocodylia), separating _Alligator_ and _Gavialis_, generally dates to the Late/Upper Cretaceous, ~90Ma. While there is an extensive crocodilian fossil record – both stem and crown – dating back to the Triassic, there are only a few well-constrained fossils in the vicinity of Crocodylia based on recent phylogenetic analyses.

### Calibrations:

**Node 731:** Crocodylia | 113.2-76.5Ma\
**Node calibrated:** The most recent common ancestor of Gavialidae (_Gavialus gangeticus_) and Alligatoridae (_Alligator mississippiensis_).\
**Fossil taxa:** †_Leidyosuchus canadensis_ (NMC 338, 1551) from the Dinosaur Park Formation, Alberta, Canada ([Lambe, 1907](https://www.biodiversitylibrary.org/page/10884799))\
**Minimum age:** Late Cretaceous (Campanian), at 76.5Ma.\
**Minimum justification:** The closest calibration is _Leidyosuchus canadensis_ [Lambe, 1907](https://www.biodiversitylibrary.org/page/10884799) from the Dinosaur Park Formation (Cretaceous: Campanian, 76.5–74.4Ma), the uppermost member of the Belly or Judith River Group of Alberta, Canada, supported as an early crown-group member of Crocodylia by numerous synapomorphies and morphological phylogenetic analyses ([Brochu 1997](https://www.tandfonline.com/doi/abs/10.1080/02724634.1997.10011017), [Rio and Mannion 2021](https://doi.org/10.7717/peerj.12094)). This topology is supported by 8 total-evidence analyses (see below), generally on the stem of Alligatoroidea.\
**Maximum age:** Early Cretaceous (Aptian–Albian), 113.2Ma\
**Maximum justification:** A conservative maximum bound is the Aptian-Albian boundary (113.2Ma), as the lower 95% CI of both times and ages is 107.2Ma and 107.9Ma, respectively, based on the density of stem crocodylians and absence of any crown members in the early Cretaceous ([Rio and Mannion 2021](https://doi.org/10.7717/peerj.12094)).\
**Discussion:** Other time-scaled parsimony analyses such as [Salas-Gismondi et al. 2019](https://www.tandfonline.com/doi/full/10.1080/14772019.2018.1495275) also support a Late Cretaceous origin for Crocodylia and a crown placement of _Leidyosuchus_, but do not report their exact age estimates and were therefore not considered.

---

**Node $XXX:** Longirostres | 113.2-72.2Ma\
**Node calibrated:** The The most recent common ancestor of Gavialidae (_Gavialus gangeticus_) and Crocodylidae (_Crocodylus niloticus_).\
**Fossil taxa:** †_Eothoracosaurus mississippiensis_ (MSU 3293) from the Ripley Formation, Mississippi, USA ([Brochu 2004](https://doi.org/10.1671/0272-4634(2004)024[0610:ANLCGC]2.0.CO;2))\
**Minimum age:** Late Cretaceous (Campanian–Maastrichtian), 72.2Ma\
**Minimum justification:** This taxon is known from the lower (early) Maastrichtian Ripley Formation and the Campanian–Maastrichtian Coon Creek Tongue Formation ([Brochu 2004](https://doi.org/10.1671/0272-4634(2004)024[0610:ANLCGC]2.0.CO;2)) \
**Maximum age:** Early Cretaceous (Aptian–Albian), 113.2Ma\
**Maximum justification:** A conservative maximum bound is the Aptian-Albian boundary (113.2Ma), as the lower 95% CI of both times and ages is 107.2Ma and 107.9Ma, respectively, based on the density of stem crocodylians and absence of any crown members in the early Cretaceous ([Rio and Mannion 2021](https://doi.org/10.7717/peerj.12094)).\
**Discussion:** The original description and several subsequent morphological and total-evidence phylogenetic analyses place eothoracosaurs on the stem of Gavalidae ([Brochu 2004](https://doi.org/10.1671/0272-4634(2004)024[0610:ANLCGC]2.0.CO;2), [Rio and Mannion 2021](https://doi.org/10.7717/peerj.12094)).


### Likelihood checkpoints

TimeTree.org estimates a median age of 87Ma (73-101Ma) from 18 studies between 2004 and 2018. To this, we added 5 additional studies from 2006–2021. Excluding outliers (1.5 * IQR; in red, below), this yields a median of 87.4Ma with a range from 70.9–110.2Ma. These data are given in crocodylia_timetree.csv. To this, we can compare 9 estimates from 8 total-evidence studies with fossil tips from 2017–2026 to estimate a range of 90–110Ma (Median 98Ma) based on the average ages and CIs. This excludes two outlier ages (as triangles, below), one from from Godoy et al. 2019 and the Groh et al. 2022 FBD analysis, which reports dramatically different topologies and timescales for Gavialoidea. These data are recorded in crocodylia_calibrations.csv.

![crocodylia likelihood checkpoints](crocodylia_calibrations.png)


## References

Brochu, C.A., 1997. A review of “Leidyosuchus”(Crocodyliformes, Eusuchia) from the Cretaceous through Eocene of North America. Journal of Vertebrate Paleontology, 17(4), pp.679-697.

Brochu, C.A., 2004. A new Late Cretaceous gavialoid crocodylian from eastern North America and the phylogenetic relationships of thoracosaurs. Journal of Vertebrate Paleontology, 24(3), pp.610-633.

Lambe, L. M. 1907. On a new crocodilian genus and species from the Judith River Formation of Alberta. Transactions of the Royal Society of Canada. Series 3. 1 (4): 219–235.

Rio, J. and Mannion, P., 2021. Phylogenetic analysis of a new morphological dataset elucidates the evolutionary history of Crocodylia and resolves the long-standing gharial problem. PeerJ.

Salas-Gismondi, R., Moreno-Bernal, J.W., Scheyer, T.M., Sánchez-Villagra, M.R. and Jaramillo, C., 2019. New Miocene Caribbean gavialoids and patterns of longirostry in crocodylians. Journal of Systematic Palaeontology, 17(12), pp.1049-1075.
