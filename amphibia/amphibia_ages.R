### Amphibia ages for likelihood checkpoints
library(ggplot2)
library(dplyr)
library(tidyr)

amphibia <- read.csv("amphibia_calibrations.csv",header=T,stringsAsFactors = T)

# --- 1) Overlapping densities on the same plot ---
dens_df <- amphibia %>%
  group_by(Clade) %>%
  reframe({
    d <- density(Age, from = 0, to = 450, adjust = 1, na.rm = TRUE)
    tibble(x = d$x, y = d$y)
  })

rug_df <- amphibia %>%
  filter(!is.na(Age)) %>%
  mutate(Clade = factor(Clade))

# y positions for each clade band (as fractions of the density height)
# we'll compute a max density height from dens_df
ymax <- max(dens_df$y, na.rm = TRUE)

rug_levels <- levels(rug_df$Clade)
y_band <- c(-0.003, -0.00225, -0.0015, -0.00075)
# y_band <- seq(from = 0.03 * ymax, to = 0.18 * ymax, length.out = length(rug_levels))
names(y_band) <- rug_levels

rug_df <- rug_df %>%
  mutate(y_pos = y_band[as.character(Clade)])

tick_h <- 0.025 * ymax  # tick height (adjust)

p <- ggplot(dens_df, aes(x = x, y = y, fill = Clade, color = Clade)) +
  geom_area(alpha = 0.25, position = "identity") +
  geom_line(linewidth = 1.0) +
  
  # stacked rugs (true stacking)
  geom_segment(
    data = rug_df,
    aes(x = Age, xend = Age, y = y_pos, yend = y_pos + tick_h, color = Clade),
    inherit.aes = FALSE,
    linewidth = 0.5,
    alpha = 0.8
  ) +
  
  coord_cartesian(xlim = c(0, 450), ylim = c(-0.002,0.03)) +
  labs(
    title = "Age density by clade",
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
