# Crocodylia calibration

One terminal node (Crocodylia), separating _Alligator_ and _Gavialis_. Generally dates to the Late/Upper Cretaceous, ~90Ma. While there is an extensive crocodilian fossil record – both stem and crown – dating back to the Triassic, there are only a few well-constrained fossils in the vicinity of Crocodylia based on recent phylogenetic analyses.

TimeTree.org estimates a median age of 87Ma (72.9-101.0Ma) from 18 studies between 2004 and 2018. To this we added 5 additional studies from 2006–2021. Excluding outliers (1.5 * IQR), this yields a median of 87.4Ma with a range from 70.9–110.2Ma. The data are given in crocodylia_timetree.csv.

To this, we can compare 8 estimates from 7 total-evidence studies with fossil tips from 2017–2025 to generate a Type II calibration density of 91.6–112.1Ma (Median 101.1Ma) based on the average dates and CIs. This excludes the outlier from the Groh et al. 2022 FBD analysis, which reports dramatically different topologies and timescales for Gavialoidea. The data are recorded in crocodylia_calibrations.csv.

The closest Type IV calibration is _Leidyosuchus canadensis_ (Cretaceous: Campanian, 77.9–72.1Ma) as an early crown-group member of Crocodylia. This placement is supported by all 8 total-evidence analyses, generally on the stem of Alligatoroidea. We therefore place a minimum bound of 77.9Ma on this node, and a maximum of 

```r
library(ggplot2)

dat <- read.csv("crocodylia_calibrations.csv",header=T)

dat$Study <- seq_len(nrow(dat))
dat <- dat[order(dat$Point), ]

q <- quantile(dat$Point, c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]
lo <- q[1] - 1.5 * iqr
hi <- q[2] + 1.5 * iqr
dat$is_outlier <- dat$Point < lo | dat$Point > hi

ggplot(dat, aes(y = factor(Study, levels = Study), x = Point)) +
  geom_errorbarh(aes(xmin = Min, xmax = Max), height = 0.15, linewidth = 0.8) +
  geom_point(aes(shape = is_outlier), size = 2.8) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17)) +
  labs(x = "Age (Ma)", y = "Study (sorted by point)",
       title = "Point estimates and reported 95% ranges") +
  theme_minimal()
```
<img width="1636" height="1174" alt="image" src="https://github.com/user-attachments/assets/d32965a9-6ab7-4e90-a0c1-8c2e9d24e060" />
