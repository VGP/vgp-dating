### Squamata: Likelihood Checkpoints
library(dplyr)
library(ggplot2)

# Read the CSV file
squamata <- read.csv("squamata_timetrees.csv", header = TRUE)
head(squamata)

# Read the tip dates
squamate_tips <- read.csv("squamate_tip_dates.csv", header = TRUE)
head(squamate_tips)

# Add a y position slightly above the x-axis
squamate_tips <- squamate_tips %>%
  mutate(y = seq(0.002, 0.002 * n(), length.out = n()))

# Identify outliers using the IQR rule
q <- quantile(squamata$Age, probs = c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]

lower <- q[1] - 1.5 * iqr
upper <- q[2] + 1.5 * iqr

squamata <- squamata %>%
  mutate(outlier = Age < lower | Age > upper)

# Plot
ggplot() +
  # Density using NON-outliers only
  geom_density(
    data = filter(squamata, !outlier),
    aes(x = Age),
    fill = "#4C72B0",
    alpha = 0.4,
    linewidth = 1,
    trim = FALSE
  ) +
  # Rug for non-outliers
  geom_rug(
    data = filter(squamata, !outlier),
    aes(x = Age),
    sides = "b",
    alpha = 0.6,
    linewidth = 0.8
  ) +
  # Rug for outliers (red)
  geom_rug(
    data = filter(squamata, outlier),
    aes(x = Age),
    sides = "b",
    color = "red",
    alpha = 0.9,
    linewidth = 1.1
  ) +
  # Whiskers (Min–Max)
  geom_errorbarh(
    data = squamate_tips,
    aes(y = y, xmin = Min, xmax = Max),
    height = 0.0005,
    linewidth = 1,
    color = "black",
    alpha = 0.8
  ) +
  
  # Central point (Point estimate)
  geom_point(
    data = squamate_tips,
    aes(y = y, x = Point),
    shape = 21,
    size = 2.5,
    fill = "white",
    color = "black",
    stroke = 1
  ) + 
  scale_x_continuous(limits = c(0, 359)) +
  labs(
    title = "Density of Squamate Age Estimates",
    x = "Age (Ma)",
    y = "Density"
  ) +
  geom_vline(
    xintercept = c(166, 215),
    linetype = "dashed",
    linewidth = 0.8,
    color = "darkgray"
  ) + 
  theme_minimal(base_size = 14) + 
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.8),
    axis.ticks = element_line(color = "black", linewidth = 0.8),
    axis.ticks.length = unit(6, "pt"),
    plot.title = element_text(face = "bold", hjust = 0.5)
  )

# Estimates
ages_clean <- squamata$Age[!squamata$outlier]

d <- density(
  ages_clean,
  from = 0,
  to   = 359
)

mode_age <- d$x[which.max(d$y)]
mode_age

median_age <- median(ages_clean)
median_age
