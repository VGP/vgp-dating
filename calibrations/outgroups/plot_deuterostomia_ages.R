## Deuterostome divergence-time estimates
library(ggplot2)
library(rphylopic)
library(ape)

## Read the ages. fileEncoding removes the invisible BOM in the first header.
ages <- read.csv("deuterostomia_ages.csv", fileEncoding = "UTF-8-BOM")

## Use the same released dated tree as the other clade checkpoints.
master <- read.csv("../master_calibrations.csv", stringsAsFactors = FALSE)
cal <- subset(master, calibration_id == "CAL001")
stopifnot(nrow(cal) == 1)
pair <- c(cal$taxon1_accession, cal$taxon2_accession)
tree <- read.nexus("../../trees/roadies_v1.1.16b.independent.fast95.tre")
tree$tip.label <- gsub("'", "", tree$tip.label, fixed = TRUE)
stopifnot(all(pair %in% tree$tip.label), is.rooted(tree), is.ultrametric(tree))
depths <- node.depth.edgelength(tree)
roadies_age <- mean(depths[seq_len(Ntip(tree))]) - depths[getMRCA(tree, pair)]

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
    fill = "#ABB6BF", color = "#8A9299", linewidth = 0.5, alpha = 0.35
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
    color = "#8A8A8A", linetype = "dotted", linewidth = 0.7,
    inherit.aes = FALSE
  ) +
  annotate(
    "segment", x = roadies_age, xend = roadies_age,
    y = -density_top * 0.19, yend = density_top * 1.43,
    color = "#246B83", linewidth = 0.8
  ) +
  ## Compact legend in the open area below the silhouettes.
  annotate(
    "segment", x = 745, xend = 766,
    y = density_top * 0.40, yend = density_top * 0.40,
    color = "#246B83", linewidth = 0.8
  ) +
  annotate(
    "segment", x = 745, xend = 766,
    y = density_top * 0.31, yend = density_top * 0.31,
    color = "#8A8A8A", linetype = "dotted", linewidth = 0.7
  ) +
  annotate(
    "segment", x = c(751, 760), xend = c(751, 760),
    y = density_top * 0.20, yend = density_top * 0.24,
    color = "#263238", linewidth = 0.7
  ) +
  annotate(
    "text", x = 775, y = density_top * c(0.40, 0.31, 0.22),
    label = c(sprintf("ROADIES · %.1f Ma", roadies_age),
              "Calibration bounds", "Published ages"),
    hjust = 0, size = 3, color = "#263238"
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
    title = "Published age estimates for Deuterostomia",
    x = "Age (Ma)",
    y = NULL
  ) +
  coord_cartesian(
    xlim = c(480, 1000),
    ylim = c(-density_top * 0.21, density_top * 1.43),
    clip = "off"
  ) +
  theme_classic(base_size = 12) +
  theme(
    plot.title = element_text(size = 17, face = "plain", margin = margin(b = 14)),
    axis.line.x = element_line(color = "black", linewidth = 0.5),
    axis.line.y = element_blank(),
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
    fill = "lightgrey"
  ) +
  add_phylopic(
    uuid = "a3dd3044-648c-4e45-93f0-21a156247132", # Echinodermata
    x = 810, y = density_top * 0.73, height = density_top * 0.40,
    fill = "lightgrey"
  ) +
  add_phylopic(
    uuid = "0871a74c-1dd1-477a-834f-d0318896ad69", # Hemichordata
    x = 915, y = density_top * 1.15, height = density_top * 0.32,
    fill = "lightgrey"
  ) +
  annotate(
    "text",
    x = c(715, 810, 915),
    y = density_top * c(1.34, 0.98, 1.34),
    label = c("Chordata", "Echinodermata", "Hemichordata"),
    fontface = "italic", size = 3.5, color = "#777777"
  )

ggsave(
  "deuterostomia_ages_density.png", plot,
  width = 9, height = 5.5, units = "in", dpi = 300, bg = "white"
)
