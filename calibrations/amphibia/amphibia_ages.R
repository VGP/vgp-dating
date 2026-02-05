### Amphibia ages for likelihood checkpoints
library(ggplot2)
library(dplyr)
library(tidyr)

amphibia <- read.csv("amphibia_calibrations.csv", header=TRUE, stringsAsFactors=TRUE)

# --- 0) Flag 1.5*IQR outliers within each clade ---
amphibia_flagged <- amphibia %>%
  group_by(Clade) %>%
  mutate(
    q1 = quantile(Age, 0.25, na.rm = TRUE),
    q3 = quantile(Age, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower = q1 - 1.5 * iqr,
    upper = q3 + 1.5 * iqr,
    is_outlier = !is.na(Age) & (Age < lower | Age > upper)
  ) %>%
  ungroup() %>%
  select(-q1, -q3, -iqr, -lower, -upper)

# Use NON-outliers for density
dens_df <- amphibia_flagged %>%
  filter(!is_outlier) %>%
  group_by(Clade) %>%
  reframe({
    d <- density(Age, from = 0, to = 450, adjust = 1, na.rm = TRUE)
    tibble(x = d$x, y = d$y)
  })

# Rugs: split into outliers vs not
rug_df <- amphibia_flagged %>%
  filter(!is.na(Age)) %>%
  mutate(Clade = factor(Clade))

rug_in <- rug_df %>% filter(!is_outlier)
rug_out <- rug_df %>% filter(is_outlier)

# Compute ymax from dens_df
ymax <- max(dens_df$y, na.rm = TRUE)

rug_levels <- levels(rug_df$Clade)
y_band <- c(-0.003, -0.00225, -0.0015, -0.00075)
names(y_band) <- rug_levels

rug_in <- rug_in %>% mutate(y_pos = y_band[as.character(Clade)])
rug_out <- rug_out %>% mutate(y_pos = y_band[as.character(Clade)])

tick_h <- 0.025 * ymax

p <- ggplot(dens_df, aes(x = x, y = y, fill = Clade, color = Clade)) +
  geom_area(alpha = 0.25, position = "identity") +
  geom_line(linewidth = 1.0) +
  
  # OUTLIER rug ticks (light gray)
  geom_segment(
    data = rug_out,
    aes(x = Age, xend = Age, y = y_pos, yend = y_pos + tick_h),
    inherit.aes = FALSE,
    linewidth = 0.5,
    alpha = 0.6,
    color = "gray80"
  ) +
  
  # NON-outlier rug ticks (colored by clade)
  geom_segment(
    data = rug_in,
    aes(x = Age, xend = Age, y = y_pos, yend = y_pos + tick_h, color = Clade),
    inherit.aes = FALSE,
    linewidth = 0.5,
    alpha = 0.85
  ) +
  
  coord_cartesian(xlim = c(0, 450), ylim = c(-0.002, 0.02)) +
  labs(
    title = "Density of estimated ages for amphibian clades",
    x = "Age (Ma)",
    y = "Density",
    fill = "Clade",
    color = "Clade"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"),
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(0.2, "cm"),
    legend.position = c(0.02, 0.98),
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = "white", color = NA),
    plot.title = element_text(face = "bold")
  )

p

# Summary Stats
age_summary <- amphibia_flagged %>%
  filter(!is_outlier) %>%
  group_by(Clade) %>%
  summarise(
    n = sum(!is.na(Age)),
    q2.5   = quantile(Age, 0.025, na.rm = TRUE),
    median = median(Age, na.rm = TRUE),
    q97.5  = quantile(Age, 0.975, na.rm = TRUE),
    .groups = "drop"
  )

age_summary
