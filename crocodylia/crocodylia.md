# Crocodylia calibration

One terminal node, separating _Alligator_ and _Gavialis_ – Crocodylia. Generally dates to the Late/Upper Cretaceous, ~90Ma. 

TimeTree.org estimates a median age of 87Ma (72.9-101.0Ma) from 18 studies between 2004 and 2018. 

To this, we can compare 5 total-evidence studies with fossil tips from 2017–2025 to generate a robust Type II calibration density of 101.1Ma (91.6–112.1Ma) based on the average dates and CIs. This excludes the outlier from the Groh et al. 2022 FBD analysiss. The data are recorded in crocodylia_calibrations.csv.

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
