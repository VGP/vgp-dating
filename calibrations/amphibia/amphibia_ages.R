### Amphibian likelihood checkpoints. Run from calibrations/amphibia.
library(ape)
library(ggplot2)
library(dplyr)
library(patchwork)
library(rphylopic)

# Preserve the existing within-clade 1.5-IQR outlier rule.
ages <- read.csv('amphibia_calibrations.csv') %>%
  group_by(Clade) %>%
  mutate(outlier = Age < quantile(Age, .25) - 1.5 * IQR(Age) |
                   Age > quantile(Age, .75) + 1.5 * IQR(Age)) %>% ungroup()
master <- read.csv('../master_calibrations.csv', stringsAsFactors = FALSE)
cal_ids <- c(Lissamphibia = 'CAL032', Batrachia = 'CAL033', Anura = 'CAL034')
files <- c(ROADIES = '../../dating/mdcat/roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre',
           ASTRAL = '../../dating/mdcat/astralpro.l6p1/astralpro.l6p1.independent.fast95.tre')
trees <- lapply(files, function(path) {
  tree <- read.nexus(path)
  tree$tip.label <- gsub("'", '', tree$tip.label, fixed = TRUE)
  stopifnot(is.rooted(tree), is.ultrametric(tree))
  tree
})
clades <- c('Lissamphibia', 'Batrachia', 'Anura', 'Gymnophiona')
pairs <- lapply(cal_ids, function(id) {
  cal <- subset(master, calibration_id == id)
  stopifnot(nrow(cal) == 1)
  c(cal$taxon1_accession, cal$taxon2_accession)
})
# Crown Gymnophiona: Rhinatrema bivittatum + Microcaecilia unicolor.
# ROADIES node 977; Gymnophiona has no calibration in the master.
pairs$Gymnophiona <- c('GCF_901001135.1', 'GCA_901765095.2')
estimates <- bind_rows(lapply(clades, function(clade) {
  bind_rows(lapply(names(trees), function(method) {
    # ASTRAL lacks salamanders: no Batrachia estimate is represented.
    if (clade == 'Batrachia' && method == 'ASTRAL') return(NULL)
    tree <- trees[[method]]; pair <- pairs[[clade]]
    stopifnot(all(pair %in% tree$tip.label))
    depths <- node.depth.edgelength(tree)
    data.frame(Clade = clade, method = method,
      age = mean(depths[seq_len(Ntip(tree))]) - depths[getMRCA(tree, pair)])
  }))
}))

# PhyloPic silhouettes: all CC0 1.0 (public-domain dedication).
# https://creativecommons.org/publicdomain/zero/1.0/
# Frog: Jose Carlos Arenas-Monroy
# https://www.phylopic.org/images/c387bde8-a9de-4101-928b-e99f2a7a33e5
# Salamander: zoosnow; contributed by T. Michael Keesey
# https://www.phylopic.org/images/d1644001-d86d-4541-9501-295a873aed2a
# Caecilian: Jose Carlos Arenas-Monroy
# https://www.phylopic.org/images/ac0368c5-05ad-4b01-bf0c-c5bc7cf85203
uuids <- c(frog = 'c387bde8-a9de-4101-928b-e99f2a7a33e5',
           salamander = 'd1644001-d86d-4541-9501-295a873aed2a',
           caecilian = 'ac0368c5-05ad-4b01-bf0c-c5bc7cf85203')
# Supply a non-file device for silhouette sizing in noninteractive runs.
if (!interactive()) grDevices::pdf(NULL)
icons <- lapply(uuids, function(id) get_phylopic(uuid = id))
colors <- c(ROADIES = '#246B83', ASTRAL = '#B7653D', Constraint = '#898989',
            Published = '#555555')
line_types <- c(ROADIES = 'solid', ASTRAL = 'longdash', Constraint = 'dotted',
                Published = 'solid')
labels <- c(ROADIES = 'ROADIES', ASTRAL = 'ASTRAL', Constraint = 'Calibration bounds',
            Published = 'Published ages; IQR outliers')
rug_key <- function(data, params, size) {
  grid::segmentsGrob(x0 = c(.35, .65), x1 = c(.35, .65), y0 = .2, y1 = .8,
    gp = grid::gpar(col = c('#555555', '#B76A61'), lwd = 1.2))
}
fill_colors <- c(Lissamphibia = '#94A99D', Batrachia = '#99AEB9',
                 Anura = '#ADBC9B', Gymnophiona = '#B0A2B8')
panels <- lapply(clades, function(clade) {
  values <- filter(ages, Clade == clade)
  retained <- filter(values, !outlier)$Age
  # Full density tails; not truncated at calibration bounds or data extrema.
  d <- density(retained, from = 0, to = 450)
  dd <- data.frame(x = d$x, y = d$y); ymax <- max(d$y)
  est <- filter(estimates, Clade == clade)
  p <- ggplot(dd, aes(x, y)) +
    geom_area(fill = fill_colors[[clade]], alpha = .38) +
    geom_line(color = fill_colors[[clade]], linewidth = .8)
  if (clade %in% names(cal_ids)) {
    cal <- subset(master, calibration_id == cal_ids[[clade]])
    p <- p + geom_segment(data = data.frame(age = c(cal$min_ma, cal$max_ma)),
      aes(x = age, xend = age, y = -.11 * ymax, yend = 1.15 * ymax,
          color = 'Constraint', linetype = 'Constraint'), inherit.aes = FALSE, linewidth = .6)
  }
  p <- p +
    geom_rug(data = filter(values, !outlier),
      aes(x = Age, color = 'Published', linetype = 'Published'), inherit.aes = FALSE,
      linewidth = .55, alpha = .7, length = unit(.025, 'npc'), key_glyph = rug_key) +
    geom_rug(data = filter(values, outlier), aes(x = Age), inherit.aes = FALSE,
      color = '#B76A61', linewidth = .6, length = unit(.025, 'npc')) +
    geom_segment(data = est,
      aes(x = age, xend = age, y = -.11 * ymax, yend = 1.15 * ymax,
          color = method, linetype = method), inherit.aes = FALSE, linewidth = .85) +
    scale_color_manual(NULL, values = colors, breaks = names(labels), labels = labels) +
    scale_linetype_manual(NULL, values = line_types, breaks = names(labels), labels = labels) +
    scale_x_continuous(breaks = seq(0, 400, 100)) +
    scale_y_continuous(breaks = scales::breaks_pretty(3),
      labels = function(x) ifelse(x < 0, '', format(x, trim = TRUE))) +
    coord_cartesian(xlim = c(0, 450), ylim = c(-.11 * ymax, 1.7 * ymax), expand = FALSE) +
    annotate('text', x = 8, y = 1.59 * ymax, label = LETTERS[match(clade, clades)],
      hjust = 0, size = 5, fontface = 'bold', color = '#333333') +
    annotate('text', x = 33, y = 1.59 * ymax, label = clade,
      hjust = 0, size = 5, color = '#333333') +
    annotate('text', x = 33, y = 1.42 * ymax,
      label = paste(sprintf('%s %.1f Ma', est$method, est$age), collapse = '   ·   '),
      hjust = 0, size = 3.2, color = '#666666') +
    labs(x = 'Age (Ma)', y = NULL) +
    theme_classic(base_size = 12) +
    theme(axis.line.y = element_blank(),
      axis.text.y = element_blank(), axis.ticks.y = element_blank(),
      axis.line = element_line(color = '#777777', linewidth = .4),
      axis.ticks = element_line(color = '#777777', linewidth = .4),
      axis.text = element_text(color = '#444444'), axis.title = element_text(color = '#444444'),
      plot.margin = margin(12, 14, 10, 10), legend.position = 'none')
  # One shared key, inside the first panel's plotting surface.
  if (clade == 'Lissamphibia') p <- p + theme(legend.position = 'inside',
    legend.position.inside = c(.025, .76), legend.justification = c(0, 1),
    legend.background = element_blank(), legend.text = element_text(size = 8),
    legend.key.height = unit(12, 'pt'), legend.key.width = unit(20, 'pt'))
  subjects <- switch(clade, Lissamphibia = c('frog', 'salamander', 'caecilian'),
    Batrachia = c('frog', 'salamander'), Anura = 'frog', Gymnophiona = 'caecilian')
  xs <- switch(clade, Lissamphibia = c(48, 118, 185), Batrachia = c(65, 145),
    Anura = 365, Gymnophiona = 380)
  for (i in seq_along(subjects)) p <- p + add_phylopic(img = icons[[subjects[i]]],
    x = xs[i], y = if (clade == 'Lissamphibia') .22 * ymax else .8 * ymax,
    width = if (length(subjects) == 1) 80 else 58, fill = '#858D89', alpha = .8)
  p
})
p <- wrap_plots(panels, ncol = 2) + plot_annotation(title = 'Published amphibian ages',
  theme = theme(plot.title = element_text(size = 23, color = '#333333'),
    plot.margin = margin(12, 12, 8, 12)))
ggsave('amphibia_likelihood_checkpoints.png', p, width = 12, height = 8.5,
  units = 'in', dpi = 300, bg = 'white')
if (interactive()) print(p)
print(estimates, row.names = FALSE)
print(ages %>% filter(!outlier) %>% group_by(Clade) %>%
  summarise(n = n(), lower = quantile(Age, .025), median = median(Age),
    upper = quantile(Age, .975)), n = Inf)

if (!interactive()) invisible(grDevices::dev.off())
