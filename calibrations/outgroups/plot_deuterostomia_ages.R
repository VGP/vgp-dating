## Deuterostome divergence-time estimates
library(ggplot2)
library(rphylopic)

## Read the ages. fileEncoding removes the invisible BOM in the first header.
ages <- read.csv("deuterostomia_ages.csv", fileEncoding = "UTF-8-BOM")

## A little headroom leaves the silhouettes clear of the density.
density_curve <- density(ages$Time, na.rm = TRUE)
density_top <- max(density_curve$y)

## Geological periods visible in the plotting window (ICS 2026/06).
timescale <- data.frame(
  period = c("Cambrian", "Ediacaran", "Cryogenian", "Tonian"),
  younger = c(486.85, 538.8, 635, 720),
  older = c(538.8, 635, 720, 1000),
  colour = c("#7FA056", "#FED96A", "#85C5A6", "#9BC6C7")
)
timescale$label_x <- (pmax(timescale$younger, 480) +
                      pmin(timescale$older, 1000)) / 2

plot <- ggplot(ages, aes(x = Time)) +
  geom_density(
    aes(y = after_stat(density)),
    fill = "#78B7C5", color = "#245A66", linewidth = 0.55, alpha = 0.55
  ) +
  ## Draw the rug at zero so the timescale can sit beneath it.
  geom_segment(
    aes(xend = Time, y = 0, yend = density_top * 0.035),
    color = "#263238", linewidth = 0.7, alpha = 0.75
  ) +
  ## Stop the boundary lines at the bottom of the timescale.
  geom_segment(
    data = data.frame(boundary = c(517.32, 590.8)),
    aes(
      x = boundary, xend = boundary,
      y = -density_top * 0.19, yend = density_top * 1.43
    ),
    color = "grey75", linetype = "dashed", linewidth = 0.7,
    inherit.aes = FALSE
  ) +
  annotate(
    "text",
    x = mean(c(517.32, 590.8)), y = density_top * 1.30,
    label = "Fossil calibration\nlimits",
    color = "grey50", size = 3
  ) +
  geom_rect(
    data = timescale,
    aes(xmin = younger, xmax = older, fill = colour),
    ymin = -density_top * 0.19, ymax = -density_top * 0.05,
    color = "white", linewidth = 0.4, inherit.aes = FALSE
  ) +
  geom_text(
    data = timescale,
    aes(x = label_x, y = -density_top * 0.12, label = period),
    size = 3.1, color = "#263238", inherit.aes = FALSE
  ) +
  scale_fill_identity() +
  scale_x_continuous(expand = expansion(mult = 0)) +
  labs(
    title = "Published Age Estimates for Deuterostomia",
    x = "Age (Ma)",
    y = "Density"
  ) +
  coord_cartesian(
    xlim = c(480, 1000),
    ylim = c(-density_top * 0.21, density_top * 1.43),
    clip = "off"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold"),
    axis.line.x = element_line(color = "black", linewidth = 0.5),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    plot.margin = margin(10, 16, 8, 8)
  )

## Fixed UUIDs make the chosen PhyloPics reproducible.
## Reuse credits and licenses are recorded in PHYLOPIC_CREDITS.md.
plot <- plot +
  add_phylopic(
    uuid = "6dec6424-7511-49b2-aac6-3da79d45c7f2", # Chordata
    x = 715, y = density_top * 1.15, height = density_top * 0.24,
    fill = "#334E68"
  ) +
  add_phylopic(
    uuid = "a3dd3044-648c-4e45-93f0-21a156247132", # Echinodermata
    x = 810, y = density_top * 0.73, height = density_top * 0.40,
    fill = "#334E68"
  ) +
  add_phylopic(
    uuid = "0871a74c-1dd1-477a-834f-d0318896ad69", # Hemichordata
    x = 915, y = density_top * 1.15, height = density_top * 0.32,
    fill = "#334E68"
  ) +
  annotate(
    "text",
    x = c(715, 810, 915),
    y = density_top * c(1.34, 0.98, 1.34),
    label = c("Chordata", "Echinodermata", "Hemichordata"),
    fontface = "italic", size = 3.5, color = "#334E68"
  )

ggsave(
  "deuterostomia_ages_density.png", plot,
  width = 9, height = 5.5, units = "in", dpi = 300, bg = "white"
)
