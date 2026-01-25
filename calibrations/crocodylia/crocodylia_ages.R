### Comparing crocodylian calibrations
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
  geom_vline(xintercept = c(77.9,113.2), linetype = "dashed", color = "darkgrey") + 
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
  annotate(
    "text",
    x = 22.5, y = 0.028,   # <-- adjust as needed
    label = "Leidysuchus canadensis",
    hjust = 0, vjust = 1,
    size = 3.5,
    color = "black",
    fontface = "italic"
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
    y=0.025,
    height=0.0035,
    fill = "lightgrey"
  )
