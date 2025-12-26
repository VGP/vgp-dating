# Amphibia calibrations

There are relatively few amphibians sampled, leaving Type III & IV calibrations primarily to a few frog groups, mostly in Neobatrachia. 

**$XXX ADD TYPE3/4 CALIBRATIONS FOR FROGS**

In contrast, we might be better served with Type I & II calibrations at the root. Previous estimates for Lissamphibia (Gymnophiona + Batrachia) with and without _Gerobatrachus_ (depending on its placement as a stem batrachian) were previously compiled by [Kligman et al. (2023)](https://www.nature.com/articles/s41586-022-05646-5). We summarize those here to obtain a 95% CI from the quantiles. Those authors also summarized the published evidence for Batrachia (Salientia + Urodela) and Gymnophiona (Rhinatrematidae + Stegokrotaphia), which we analyzed in the same manner:

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
