### Squamata: Likelihood Checkpoints
library(ape)
library(dplyr)
library(ggplot2)

# Read the CSV file
squamata <- read.csv("squamata_timetrees.csv", header = TRUE)

# Read the tip dates
squamate_tips <- read.csv("squamate_tip_dates.csv", header = TRUE)

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

## Current crown ages from the CAL064 defining pair.
master <- read.csv("../master_calibrations.csv", stringsAsFactors = FALSE)
cal <- subset(master, calibration_id == "CAL064")
stopifnot(nrow(cal) == 1)
pair <- c(cal$taxon1_accession, cal$taxon2_accession)
files <- c(ROADIES = "../../trees/roadies_v1.1.16b.independent.fast95.tre",
           ASTRAL = "../../trees/astralpro.l6p1.independent.fast95.tre")
node_age <- function(path) {
  tree <- read.nexus(path)
  tree$tip.label <- gsub("'", "", tree$tip.label, fixed = TRUE)
  stopifnot(all(pair %in% tree$tip.label), is.rooted(tree), is.ultrametric(tree))
  depths <- node.depth.edgelength(tree)
  mean(depths[seq_len(Ntip(tree))]) - depths[getMRCA(tree, pair)]
}
estimates <- data.frame(method = names(files), age = vapply(files, node_age, numeric(1)))
age_labels <- setNames(sprintf("%s · %.1f Ma", estimates$method, estimates$age), names(files))

line_labels <- c(
  age_labels,
  Constraint = sprintf("Calibration bounds · %.1f–%.1f Ma", cal$min_ma, cal$max_ma),
  Published = "Published ages; IQR outliers"
)

# One paired tick key explains both rug colors.
rug_key <- function(data, params, size) {
  grid::segmentsGrob(
    x0 = c(0.35, 0.65), x1 = c(0.35, 0.65), y0 = 0.2, y1 = 0.8,
    gp = grid::gpar(col = c("#555555", "#B76A61"), lwd = 1.2)
  )
}

# Preserve the published-age distributions and fossil-tip intervals.
p <- ggplot() +
  geom_density(data = filter(squamata, !outlier), aes(x = Age),
               fill = "#ABB6BF", color = "#8A9299", alpha = 0.35, linewidth = 0.5) +
  geom_vline(data = data.frame(age = c(cal$min_ma, cal$max_ma)),
             aes(xintercept = age, color = "Constraint", linetype = "Constraint"), linewidth = 0.6) +
  geom_rug(data = filter(squamata, !outlier),
           aes(x = Age, color = "Published", linetype = "Published"),
           sides = "b", alpha = 0.6, linewidth = 0.5, key_glyph = rug_key) +
  geom_rug(data = filter(squamata, outlier), aes(x = Age),
           sides = "b", color = "#B76A61", alpha = 0.7, linewidth = 0.5) +
  geom_vline(data = estimates, aes(xintercept = age, color = method, linetype = method), linewidth = 0.9) +
  geom_errorbar(data = squamate_tips, aes(y = y, xmin = Min, xmax = Max),
                orientation = "y", width = 0.0005, linewidth = 0.6, color = "#444444") +
  geom_point(data = squamate_tips, aes(x = Point, y = y, shape = "Estimate"),
             size = 2.2, color = "#444444", fill = "white") +
  scale_shape_manual(name = "Fossil-tip ages; bars: reported intervals",
                     values = c(Estimate = 21)) +
  scale_color_manual(name = NULL,
                     values = c(ROADIES = "#246B83", ASTRAL = "#B7653D",
                                Constraint = "#8A8A8A", Published = "#555555"),
                     breaks = names(line_labels), labels = line_labels) +
  scale_linetype_manual(name = NULL,
                        values = c(ROADIES = "solid", ASTRAL = "longdash",
                                   Constraint = "dotted", Published = "solid"),
                        breaks = names(line_labels), labels = line_labels) +
  scale_x_continuous(breaks = seq(0, 350, 50)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  coord_cartesian(xlim = c(0, 359)) +
  labs(title = "Age estimates for Squamata", x = "Age (Ma)", y = "Density") +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 1),
         shape = guide_legend(order = 2)) +
  theme_classic(base_size = 12) +
  theme(axis.line = element_line(color = "#777777", linewidth = 0.4),
        axis.ticks = element_line(color = "#777777", linewidth = 0.4),
        axis.text = element_text(color = "#444444"),
        axis.title = element_text(color = "#444444"),
        plot.title = element_text(size = 17, face = "plain", margin = margin(b = 14)),
        legend.position = "inside", legend.position.inside = c(0.03, 0.97),
        legend.justification = c(0, 1), legend.box = "vertical",
        legend.box.just = "left", legend.background = element_blank(),
        legend.text = element_text(size = 8), legend.title = element_text(size = 8),
        legend.key.width = unit(18, "pt"), legend.key.height = unit(14, "pt"),
        legend.spacing.y = unit(0, "pt"),
        plot.margin = margin(16, 18, 8, 12))

ggsave("squamata_likelihood_checkpoints.png", p, width = 8, height = 5,
       units = "in", dpi = 300, bg = "white")
if (interactive()) print(p)
print(estimates, row.names = FALSE)

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
