# Amphibia calibrations

There are relatively few amphibians sampled, leaving Type III & IV calibrations primarily to a few frog groups, mostly in Neobatrachia. 

The total-evidence analysis of [Chen et al. 2016](https://www.nature.com/articles/srep19209) estimated _Eodiscoglossus santonjae_ in the crown of Anura, corroborated by the morphological re-description by [Baez and Gomez 2016](https://ri.conicet.gov.ar/handle/11336/60180) and re-analysis by [Gao and Chen 2017](https://bioone.org/journals/American-Museum-Novitates/volume-2017/issue-3876/3876.1/A-New-Crown-Group-Frog-Amphibia--Anura-from-the/10.1206/3876.1.short). This taxon dates to the Barremian, ~121.4–125.8Ma. Other putative crown-group anurans are known from similar ages as summarized in [Gomez and Andres 2019](https://www.sciencedirect.com/science/article/pii/S1631068319301320), but these are not as well-documented. Consequently, we place a minimum bound of 121.4Ma on the MRCA of Anura, with a maximum of 252Ma for the maximum age of the Triassic.

There are well-documented times for likelihood checkpoints at the root. Previous estimates for Lissamphibia (Gymnophiona + Batrachia) with and without _Gerobatrachus_ (depending on its placement as a stem batrachian) were previously compiled by [Kligman et al. (2023)](https://www.nature.com/articles/s41586-022-05646-5). We summarize those here to obtain a 95% CI from the quantiles. Those authors also summarized the published evidence for Batrachia (Salientia + Urodela) and Gymnophiona (Rhinatrematidae + Stegokrotaphia), which we analyzed in the same manner:

Lissamphibia with _Gerobatrachus_: 278–361Ma (Median 320Ma)\
Lissamphibia without _Gerobatrachus_: 316–363Ma (Median 326Ma)\
Batrachia: 219–348Ma (Median 292Ma)\
Gymnophiona: 91.6–259Ma (Median 216Ma)

```r
library(ggplot2)
library(dplyr)
library(tidyr)

amphibia <- read.csv("amphibia_calibrations.csv",header=T,stringsAsFactors = T)

# --- 1) Overlapping densities on the same plot ---
p <- ggplot(amphibia, aes(x = Age, fill = Clade, color = Clade)) +
  geom_density(alpha = 0.25, linewidth = 1.0, adjust = 1) +
  labs(
    title = "Age density by clade",
    x = "Age (Ma)",
    y = "Density",
    fill = "Clade",
    color = "Clade"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

p

# --- 2) 95% interval (2.5% & 97.5%) + median for each clade ---
age_summary <- amphibia %>%
  group_by(Clade) %>%
  summarise(
    n = sum(!is.na(Age)),
    q2.5   = quantile(Age, 0.025, na.rm = TRUE),
    median = median(Age, na.rm = TRUE),
    q97.5  = quantile(Age, 0.975, na.rm = TRUE),
    .groups = "drop"
  )

age_summary
```
<img width="1636" height="1174" alt="image" src="https://github.com/user-attachments/assets/f5a1804b-ff29-461b-8027-8e722b3af241" />

## References

Baez, A.M. and Gomez, R.O., 2016. Revision of the skeletal morphology of Eodiscoglossus santonjae, an Early Cretaceous frog from northeastern Spain, with comments on its phylogenetic placement. Acta Musei Nationalis Pragae Series B Historia Naturalis 72(1-2):66-77.

Chen, J., Bever, G.S., Yi, H.Y. and Norell, M.A., 2016. A burrowing frog from the late Paleocene of Mongolia uncovers a deep history of spadefoot toads (Pelobatoidea) in East Asia. Scientific Reports, 6(1), p.19209.

Gao, K.Q. and Chen, J., 2017. A new crown-group frog (Amphibia: Anura) from the Early Cretaceous of northeastern Inner Mongolia, China. American Museum Novitates, 2017(3876), pp.1-39.

Gómez, R.O. and Lires, A.I., 2019. High ecomorphological diversity among Early Cretaceous frogs from a large subtropical wetland of Iberia. Comptes Rendus Palevol, 18(7), pp.711-723.

Kligman, B.T., Gee, B.M., Marsh, A.D., Nesbitt, S.J., Smith, M.E., Parker, W.G. and Stocker, M.R., 2023. Triassic stem caecilian supports dissorophoid origin of living amphibians. Nature, 614(7946), pp.102-107.
