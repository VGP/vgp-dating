# Turtle likelihood checkpoints
library(ape)
library(rphylopic)
library(ggplot2)
library(dplyr)

# Read in ages
testudines <- read.csv("testudines_timetrees.csv", header = TRUE)

# ----------------------------
# IQR-based outlier detection
# ----------------------------
q <- quantile(testudines$Time, probs = c(0.25, 0.75), na.rm = TRUE)
iqr <- q[2] - q[1]

lower <- q[1] - 1.5 * iqr
upper <- q[2] + 1.5 * iqr

testudines <- testudines %>%
  mutate(outlier = Time < lower | Time > upper)

# Oxfordian-filtered data (>= 157.3 Ma)
testudines_ox <- testudines %>%
  filter(!outlier, Time >= 157.3)

# ----------------------------
# IQR-based outlier detection (Oxfordian only)
# ----------------------------
qO <- quantile(testudines_ox$Time, probs = c(0.25, 0.75), na.rm = TRUE)
iqrO <- qO[2] - qO[1]

lowerO <- qO[1] - 1.5 * iqrO
upperO <- qO[2] + 1.5 * iqrO

testudines_ox <- testudines_ox %>%
  mutate(outlier_O = Time < lowerO | Time > upperO)

# ----------------------------
# Median & density mode
# (NON-outliers only)
# ----------------------------
ages_clean  <- testudines$Time[!testudines$outlier]
ages_cleanO <- testudines_ox$Time[!testudines_ox$outlier_O]

d  <- density(ages_clean,  from = 0, to = 300)
dO <- density(ages_cleanO, from = 0, to = 300)

mode_time_all   <- d$x[which.max(d$y)]
median_time_all <- median(ages_clean)

mode_time_ox   <- dO$x[which.max(dO$y)]
median_time_ox <- median(ages_cleanO)

# Current crown ages, identified by the CAL074 defining pair.
master <- read.csv("../master_calibrations.csv", stringsAsFactors = FALSE)
cal <- subset(master, calibration_id == "CAL074")
stopifnot(nrow(cal) == 1)
pair <- c(cal$taxon1_accession, cal$taxon2_accession)
files <- c(ROADIES = "../../dating/mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre",
           ASTRAL = "../../dating/mdcat/astralpro.l6p1/astralpro.l6p1.independent.fast95.tre")
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
  Published = "Published ages; red <157.3 Ma or outliers"
)

# One paired tick key explains both rug colors.
rug_key <- function(data, params, size) {
  grid::segmentsGrob(
    x0 = c(0.35, 0.65), x1 = c(0.35, 0.65), y0 = 0.2, y1 = 0.8,
    gp = grid::gpar(col = c("#555555", "#B76A61"), lwd = 1.2)
  )
}

# Published distributions retain the existing IQR and Oxfordian filters.
p <- ggplot() +
  geom_density(data = filter(testudines, !outlier), aes(x = Time, fill = "All"),
               color = "#8A9299", alpha = 0.35, linewidth = 0.5) +
  geom_density(data = filter(testudines_ox, !outlier_O), aes(x = Time, fill = "Oxfordian Only"),
               color = "#77786D", alpha = 0.35, linewidth = 0.5) +
  geom_vline(data = data.frame(age = c(cal$min_ma, cal$max_ma)),
             aes(xintercept = age, color = "Constraint", linetype = "Constraint"),
             linewidth = 0.6) +
  geom_rug(data = filter(testudines, !outlier, Time >= 157.3),
           aes(x = Time, color = "Published", linetype = "Published"),
           sides = "b", alpha = 0.6, linewidth = 0.5, key_glyph = rug_key) +
  geom_rug(data = filter(testudines, outlier | Time < 157.3),
           aes(x = Time, color = "Excluded", linetype = "Excluded"),
           sides = "b", alpha = 0.7, linewidth = 0.5, show.legend = FALSE) +
  geom_vline(data = estimates, aes(xintercept = age, color = method, linetype = method), linewidth = 0.9) +
  scale_fill_manual(name = NULL, values = c("All" = "#ABB6BF", "Oxfordian Only" = "#C4C3AF")) +
  scale_color_manual(name = NULL, values = c(ROADIES = "#246B83", ASTRAL = "#B7653D", Constraint = "#8A8A8A",
                                    Published = "#555555", Excluded = "#B76A61"),
                     breaks = names(line_labels), labels = line_labels) +
  scale_linetype_manual(name = NULL, values = c(ROADIES = "solid", ASTRAL = "longdash", Constraint = "dotted",
                                       Published = "solid", Excluded = "solid"),
                        breaks = names(line_labels), labels = line_labels) +
  scale_x_continuous(limits = c(0, 300), breaks = seq(0, 300, by = 50)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(title = "Age estimates for Testudines", x = "Age (Ma)", y = NULL) +
  guides(color = guide_legend(order = 1), linetype = guide_legend(order = 1),
         fill = guide_legend(order = 2)) +
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
        legend.text = element_text(size = 8),
        legend.key.width = unit(18, "pt"), legend.key.height = unit(14, "pt"),
        legend.spacing.y = unit(0, "pt"),
        plot.margin = margin(16, 18, 8, 12))

# Hermann's tortoise (Testudo hermanni), PhyloPic CC0 1.0.
# https://www.phylopic.org/images/5170633b-b867-4c98-acc0-fbb823fc0aaa/testudo-hermanni
p <- p + add_phylopic(
  uuid = "5170633b-b867-4c98-acc0-fbb823fc0aaa",
  x = 55, y = 0.0046, height = 0.0035, fill = "lightgrey"
)

ggsave("testudines_timetree_estimates.png", p, width = 8, height = 5,
       units = "in", dpi = 300, bg = "white")
if (interactive()) print(p)
print(estimates, row.names = FALSE)

# ----------------------------
# Print results
# ----------------------------
cat("Testudines age summary\n")
cat("--------------------------------\n")

cat("ALL AGES (IQR-based)\n")
cat("Total estimates:     ", nrow(testudines), "\n")
cat("Non-outliers:        ", sum(!testudines$outlier), "\n")
cat("Outliers:            ", sum(testudines$outlier), "\n")
cat(sprintf("IQR bounds:          %.1f – %.1f Ma\n", lower, upper))
cat(sprintf("Median age:          %.1f Ma\n", median_time_all))
cat(sprintf("Density mode:        %.1f Ma\n\n", mode_time_all))

cat("OXFORDIAN ONLY (≥157.3 Ma; IQR-based)\n")
cat("Total estimates:     ", nrow(testudines_ox), "\n")
cat("Non-outliers:        ", sum(!testudines_ox$outlier_O), "\n")
cat("Outliers:            ", sum(testudines_ox$outlier_O), "\n")
cat(sprintf("IQR bounds:          %.1f – %.1f Ma\n", lowerO, upperO))
cat(sprintf("Median age:          %.1f Ma\n", median_time_ox))
cat(sprintf("Density mode:        %.1f Ma\n", mode_time_ox))
