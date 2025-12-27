# Crocodylia calibration

One terminal node (Crocodylia), separating _Alligator_ and _Gavialis_. Generally dates to the Late/Upper Cretaceous, ~90Ma. While there is an extensive crocodilian fossil record – both stem and crown – dating back to the Triassic, there are only a few well-constrained fossils in the vicinity of Crocodylia based on recent phylogenetic analyses.

TimeTree.org estimates a median age of 87Ma (72.9-101.0Ma) from 18 studies between 2004 and 2018. To this we added 5 additional studies from 2006–2021. Excluding outliers (1.5 * IQR), this yields a median of 87.4Ma with a range from 70.9–110.2Ma. The data are given in crocodylia_timetree.csv.

To this, we can compare 8 estimates from 7 total-evidence studies with fossil tips from 2017–2025 to estimate a range of 88.3–107.9Ma (Median 97.4Ma) based on the average ages and CIs. This excludes two outlier ages, one from from Godoy et al. 2019 and the Groh et al. 2022 FBD analysis, which reports dramatically different topologies and timescales for Gavialoidea. The data are recorded in crocodylia_calibrations.csv.

The closest Type IV calibration is _Leidyosuchus canadensis_ (Cretaceous: Campanian, 77.9–72.1Ma) as an early crown-group member of Crocodylia. This placement is supported by all 8 total-evidence analyses, generally on the stem of Alligatoroidea. We therefore place a minimum bound of 77.9Ma on this node. A possible maximum bound is the lower Albian (113.2-100.5Ma), as the lower 95% CI of both times and ages is 107.2Ma and 107.9Ma, respectively.

```r
library(rphylopic)
library(ggplot2)
library(dplyr)

## Read in data
ages <- read.csv("crocodylia_calibrations.csv",header=T)
times <- read.csv("crocodylia_timetree.csv",header=T)

## --- Time outlier bounds (IQR) ---
bounds <- times %>%
  summarise(
    q1  = quantile(Time, 0.25, na.rm = TRUE),
    q3  = quantile(Time, 0.75, na.rm = TRUE),
    iqr = IQR(Time, na.rm = TRUE)
  )

lo_t <- bounds$q1 - 1.5 * bounds$iqr
hi_t <- bounds$q3 + 1.5 * bounds$iqr

times <- times %>%
  mutate(is_outlier = Time < lo_t | Time > hi_t)

times_no_outliers <- times %>%
  filter(!is_outlier)

## --- Prepare ages ---
ages$Study <- seq_len(nrow(ages))
ages <- ages[order(ages$Point), ]

q   <- quantile(ages$Point, c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]
lo  <- q[1] - 1.5 * iqr
hi  <- q[2] + 1.5 * iqr
ages$is_outlier <- ages$Point < lo | ages$Point > hi

## --- Density height for stacking within it ---
d <- density(times_no_outliers$Time, na.rm = TRUE)
ymax <- max(d$y)

## Stack ages *within* the density
ages$y_pos <- seq(from = 0.05 * ymax, to = 0.95 * ymax, length.out = nrow(ages))

## --- Plot ---
ggplot() +
  geom_density(
    data = times_no_outliers,
    aes(x = Time, y = after_stat(density)),
    fill = "lightblue", alpha = 0.5
  ) +
  geom_vline(xintercept = 77.9, linetype = "dashed", color = "darkgrey") + 
  ## rug: non-outliers (black)
  geom_rug(
    data = filter(times, !is_outlier),
    aes(x = Time),
    sides = "b", color = "black", alpha = 0.6
  ) +
  ## rug: outliers (red)
  geom_rug(
    data = filter(times, is_outlier),
    aes(x = Time),
    sides = "b", color = "red", alpha = 0.9
  ) +
  ## calibration ranges (overlaid on density)
  geom_errorbarh(
    data = ages,
    aes(y = y_pos, xmin = Min, xmax = Max),
    inherit.aes = FALSE,
    height = 0.02 * ymax, linewidth = 0.8
  ) +
  ## calibration points
  geom_point(
    data = ages,
    aes(x = Point, y = y_pos, shape = is_outlier),
    inherit.aes = FALSE,
    size = 2.4
  ) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 17)) +
  coord_cartesian(xlim = c(0, 225)) +
  labs(
    title = "Empirical Density of Times and Ages for Crocodylia",
    x = "Millions of Years",
    y = "Density",
    shape = "Age Outlier:"
  ) +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    legend.position = c(0.85, 0.65),
    legend.background = element_rect(fill = "white", color = "white"),
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(0.2, "cm")
  ) + 
  add_phylopic(
    uuid = "a796420f-5158-4e96-acbe-e30ef36b26d6",
    x=170,
    y=0.01,
    height=0.0065
  ) + 
  add_phylopic(
    uuid = "9ae2be6e-95fa-4514-955e-130236fc07b7",
    x=50,
    y=0.0265,
    height=0.0035,
    fill = "lightgrey"
  )
```
<img width="1636" height="1174" alt="image" src="https://github.com/user-attachments/assets/1827c70b-adb0-42b0-9d27-451d72ebea49" />
