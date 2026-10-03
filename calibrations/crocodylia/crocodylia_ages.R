### Comparing crocodylian calibrations
library(ape)
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

## Current crown ages from the CAL083 defining pair.
master <- read.csv("../master_calibrations.csv", stringsAsFactors = FALSE)
cal <- subset(master, calibration_id == "CAL083")
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
  geom_density(data = times_no_outliers, aes(x = Time),
               fill = "#ABB6BF", color = "#8A9299", alpha = 0.35, linewidth = 0.5) +
  geom_vline(data = data.frame(age = c(cal$min_ma, cal$max_ma)),
             aes(xintercept = age, color = "Constraint", linetype = "Constraint"), linewidth = 0.6) +
  geom_rug(data = filter(times, !is_outlier),
           aes(x = Time, color = "Published", linetype = "Published"),
           sides = "b", alpha = 0.6, linewidth = 0.5, key_glyph = rug_key) +
  geom_rug(data = filter(times, is_outlier), aes(x = Time),
           sides = "b", color = "#B76A61", alpha = 0.7, linewidth = 0.5) +
  geom_vline(data = estimates, aes(xintercept = age, color = method, linetype = method), linewidth = 0.9) +
  geom_errorbar(data = ages, aes(y = y_pos, xmin = Min, xmax = Max),
                orientation = "y", width = 0.02 * ymax, linewidth = 0.6, color = "#444444") +
  geom_point(data = ages, aes(x = Point, y = y_pos, shape = is_outlier),
             size = 2.2, color = "#444444") +
  scale_shape_manual(name = "Fossil-tip ages; bars: reported intervals",
                     values = c(`FALSE` = 16, `TRUE` = 17),
                     labels = c(`FALSE` = "Estimate", `TRUE` = "IQR outlier")) +
  scale_color_manual(name = NULL,
                     values = c(ROADIES = "#246B83", ASTRAL = "#B7653D",
                                Constraint = "#8A8A8A", Published = "#555555"),
                     breaks = names(line_labels), labels = line_labels) +
  scale_linetype_manual(name = NULL,
                        values = c(ROADIES = "solid", ASTRAL = "longdash",
                                   Constraint = "dotted", Published = "solid"),
                        breaks = names(line_labels), labels = line_labels) +
  scale_x_continuous(breaks = seq(0, 200, 25)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  coord_cartesian(xlim = c(0, 201.4)) +
  labs(title = "Age estimates for Crocodylia", x = "Age (Ma)", y = NULL) +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 1),
         shape = guide_legend(order = 2)) +
  theme_classic(base_size = 12) +
  theme(axis.line.y = element_blank(),
      axis.text.y = element_blank(), axis.ticks.y = element_blank(),
      axis.line = element_line(color = "#777777", linewidth = 0.4),
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
        plot.margin = margin(16, 18, 8, 12)) +
  add_phylopic(uuid = "a796420f-5158-4e96-acbe-e30ef36b26d6",
               x = 170, y = 0.009, height = 0.0065, fill = "lightgrey")

ggsave("crocodylia_calibrations.png", p, width = 8, height = 5,
       units = "in", dpi = 300, bg = "white")
if (interactive()) print(p)
print(estimates, row.names = FALSE)
