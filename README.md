# VGP Phase I dating – assembling fossil calibrations

## Team
**Coordinator:** Alex Pyron (rpyron@gwu.edu) – The George Washington University

**Contributors:**\
Tom Near (thomas.near@yale.edu) – Yale (Fishes)\
Tiago Simões (simoes@princeton.edu) – Princeton (Squamates)\
Santiago Claramunt (sclaramu@uno.edu) – New Orleans (Birds)\
Ricardo Betancur (rbetancur@ucsd.edu) – UC San Diego (Fishes)\
Nate Upham (nathan.upham@asu.edu) – Arizona State (Mammals)\
Chase Brownstein (chase.brownstein@yale.edu) – Yale (Fishes)\
Mario dos Reis (m.dosreisbarros@qmul.ac.uk) – Queen Mary (Mammals & methods)


## Final calibrations

Here is the [final set](./calibrations/calibrations.md) of **$XXX** calibrations decided on by our working group.


## Aims & Scope

Here is the [final tree](https://github.com/VGP/vgp-trees/tree/main/phase-1) in [newick](https://github.com/VGP/vgp-trees/blob/main/phase-1/roadies_v1.1.16b.nwk). Other PDFs with different taxon labels are available at the repo. We will base our nodal constraints on this topology. Given the limited taxon sampling and absence of fossil tips, this exercise will in many ways be simplified and reminiscent of earlier eras in the field of divergence-time estimation. Our primary aim here is to generate well-constrained ranges for a variety of nodes across the tree, to produce a robustly calibrated timescale for vertebrate evolution. This should be congruent with the fossil record and with existing consensus estimates for the origin of various groups.

In practice, this will primarily be a collection of min & max ages – perhaps 50 to 60 – scattered and spaced across the tree. Given the increasing prevalence of fossil-tip-dated phylogenies for the major clades and the overall vertebrate tree, much of the previous ambiguity and controversy over the placement and applicability of many fossils will hopefully be alleviated. However, the constraints of the sampling and the lack of direct fossil inclusion induces its own set of considerations for which we will need to account.

This feeds into the need for equivalent standards, practices, and criteria for the inclusion of calibrations, as well as resolving disputes over conflicting interpretations. The breadth of the team members should contribute to this discussion, as we progress towards a harmonized set of constraints and their application in our dating pipeline. The actual methods and analyses used in that pipeline represent a secondary set of considerations to be developed in concert.

To begin with, we can outline four types of possible calibrations that can be drawn from team expertise, the literature, and existing analyses. This outline can provide some initial structure for us to begin compiling bounds and ranges. We can modify this set of considerations as we go. The strength of evidence will generally range from explicit phylogenetic hypotheses for fossil placement based on combined-evidence, tip-dated analysis, to expert-assessed consensus over the likely stratigraphic range during which a stem- or crown-group arose.


## Calibration types

**Type I – stage-based internal & root nodes:** For many nodes such as the root, age calibrations will primarily refer to stratigraphic ranges based on initial taxon appearances and expert-assessed consensus for the upper bounds. A key example is the root, which [likely dates](https://www.nature.com/articles/nature16150) to the mid-Ediacaran ~570Ma and will presumably therefore receive a range of ~541–635Ma. The impact of fossil material is generally indirect in these instances. Only a few nodes should receive calibrations of this type, mostly towards the root of the tree.

**Type II – stage-based terminal nodes:** Another major consideration induced by our limited taxon-sampling is the presence of deeply diverged (i.e., >50Ma) lineages at the tips, some with relatively short branches. A prominent example are the only two crocodilians, _Alligator_ and _Gavialis_, which likely diverged in the [Late Cretaceous](https://link.springer.com/article/10.1186/s12862-020-01642-3) but have very short terminal branch-lengths in the final tree. We must take care to scrutinize these tip-level divergences to ensure that they don’t yield artificially low ages. In such instances, unless there are serendipitously-proximal fossils, they will likely need to be constrained to stratigraphic ranges or consensus bounds based on our expert assessment. There may be many of these instances depending on how the initial dating runs perform near the tips of the tree.

**Type III – non-phylogenetic fossils:** This represents the classic instance of well-characterized fossils that are widely considered to represent the earliest stem- or crown-group members of a clade based on diagnostic taxonomic characteristics, but which have not been included in a total-evidence analysis for fossil-tip dating. Such fossils provide strong minimum ages, with maximum bounds set according to usual principles such as the stratigraphic range or the next-oldest constrained divergence – an extensive literature exists for this question. Ideally, this type of calibration will be minimal, as most fossils will ideally have been included in trees.

**Type IV – phylogenetic fossils:** The ideal type of calibration will derive from a recent total-evidence phylogenetic analysis that includes the fossil of interest and therefore provides an objective reference for its placement in our tree, along with a median age estimate and confidence interval on the stem and crown ages. Ideally, most of our calibrations will derive from such sources. Luckily, many such estimates have been published recently for most major clades, so each team has an extensive set of resources from which to work.


## Syntax

Either Siavash or I will add a reference tree based on roadies_v1.1.16b.nwk with APE-style node numbers from R to facilitate objective reference to nodes. Minimal documentation will be:\
	-Node number and lineage\
	-Type of calibration: I–IV\
	-Minimum and maximum ages in Ma: e.g., 234.5,456.2\
	-Associated fossil material and rationale\
	-Citations and references


## Alternatives & Complements

There are three major ways that we might explore robustness and congruence in addition to solely implementing min-max age constraints for fossil calibration. 

The first is that we can select one or several tip-sampled phylogenies to fix the node ages using an approach such as [congruify](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210X.12051) based on a dataset such as [Tetrapod1.0](https://pubmed.ncbi.nlm.nih.gov/41041580/). 

A second, related approach would be to do this using more recent trees for each subclade and patching them together using a fixed, dated backbone for Deuterostomia or Vertebrata.

A third strategy is to derive all calibration ranges from the empirical distribution of dates and ages for a set of clades (perhaps all Superorders and subtending nodes) from [timetree.org](http://timetree.org), giving a broadly sampled prior distribution from combined previous studies.

This empirical prior can then be used to (i) produce a dated tree using these constraints alone, and (ii) employing them as post-hoc probabilistic calibration checks in a likelihood framework sensu [Pyron (2010)](https://pubmed.ncbi.nlm.nih.gov/20525629/).

We can also use these empirical priors in a cross-validation framework to identify which nodes exibit the most variance under different calibration strategies, as an additional indicator of robustness.


## Analytical Methods

This is a secondary consideration that we can discuss as a group, hopefully to be conducted by a subset of team members. Basic approaches such as [treePL](/treePL/treePL.md) will likely form the core of our initial testing pipelines, but we should explore a range of options. Approaches such as [RevBayes](https://revbayes.github.io/tutorials/dating/) and [mcmctree](https://github.com/dosreislab/mcmctree) would allow us to exploit more accuracy and precision from our whole-genome data – fulfilling a core aim of the VGP, to demonstrate how these data allow superior inference over previous approaches – but will likely face significant computational burdens and runtime constraints. This is an open area of inquiry for our group.
