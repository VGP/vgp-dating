# Plot TimeTree estimates against the released MD-CAT trees and current bounds.
# Run from any directory: Rscript calibrations/plot_checkpoints.R
suppressPackageStartupMessages({ library(ape); library(ggplot2) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
plots <- list(
  CAL005 = c('Vertebrata', 'vertebrates/vertebrata_likelihood_checkpoints.png'),
  CAL009 = c('Teleostei', 'fishes/teleostei_likelihood_checkpoints.png'),
  CAL028 = c('Tetrapoda', 'tetrapods/tetrapoda_likelihood_checkpoints.png'),
  CAL040 = c('Mammalia', 'mammals/mammalia_likelihood_checkpoints.png'),
  CAL006 = c('Cyclostomata', 'vertebrates/cyclostomata_likelihood_checkpoints.png'),
  CAL007 = c('Gnathostomata', 'vertebrates/gnathostomata_likelihood_checkpoints.png'),
  CAL008 = c('Osteichthyes', 'vertebrates/osteichthyes_likelihood_checkpoints.png'),
  CAL025 = c('Chondrichthyes', 'fishes/chondrichthyes_likelihood_checkpoints.png'),
  CAL029 = c('Amniota', 'tetrapods/amniota_likelihood_checkpoints.png'),
  CAL030 = c('Sauria', 'tetrapods/sauria_likelihood_checkpoints.png'),
  CAL031 = c('Archosauria', 'tetrapods/archosauria_likelihood_checkpoints.png'),
  CAL041 = c('Theria', 'mammals/theria_likelihood_checkpoints.png'),
  CAL044 = c('Placentalia', 'mammals/placentalia_likelihood_checkpoints.png')
)
windows <- list(CAL005 = c(400, 850), CAL009 = c(0, 400),
                CAL028 = c(200, 500), CAL040 = c(50, 300),
                CAL006 = c(200, 750), CAL007 = c(300, 700), CAL008 = c(200, 600), CAL025 = c(250, 550),
                CAL029 = c(100, 500), CAL030 = c(150, 400), CAL031 = c(150, 400),
                CAL041 = c(50, 300), CAL044 = c(0, 200))
# Approximate geological-period boundaries (Ma), for context rather than dating.
periods <- data.frame(
  period = c('Quaternary', 'Neogene', 'Paleogene', 'Cretaceous', 'Jurassic', 'Triassic',
             'Permian', 'Carboniferous', 'Devonian', 'Silurian', 'Ordovician',
             'Cambrian', 'Ediacaran', 'Cryogenian', 'Tonian'),
  younger = c(0, 2.58, 23.03, 66, 145, 201.4, 251.9, 298.9, 358.9, 419.2, 443.8, 486.9, 538.8, 635, 720),
  older = c(2.58, 23.03, 66, 145, 201.4, 251.9, 298.9, 358.9, 419.2, 443.8, 486.9, 538.8, 635, 720, 1000),
  colour = c('#F4EBD2', '#EEE0AC', '#E8CCB2', '#C5DAB7', '#B9D5D9', '#D5C5DB',
             '#DABEB4', '#C4D1BF', '#E0CFB2', '#C9DFCD', '#B4D1C8',
             '#C4D1AD', '#E8DBA9', '#BFD8C9', '#BED4D3')
)
tree_files <- c(ROADIES = 'roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre',
                ASTRAL = 'astralpro.l6p1/astralpro.l6p1.independent.fast95.tre')
trees <- lapply(file.path(root, 'dating/mdcat', tree_files), function(path) {
  tree <- read.nexus(path)
  tree$tip.label <- gsub("'", '', tree$tip.label, fixed = TRUE)
  stopifnot(is.rooted(tree), is.ultrametric(tree))
  tree
})
names(trees) <- names(tree_files)
requested <- commandArgs(trailingOnly = TRUE)
for (id in if (length(requested)) intersect(names(plots), requested) else names(plots)) {
  cal <- master[master$calibration_id == id, ]
  data <- estimates[estimates$calibration_id == id, ]
  stopifnot(nrow(cal) == 1, nrow(data) > 1, all(is.finite(data$age_ma)))
  pair <- c(cal$taxon1_accession, cal$taxon2_accession)
  ages <- data.frame(method = names(trees), age = vapply(trees, function(tree) {
    stopifnot(all(pair %in% tree$tip.label))
    depth <- node.depth.edgelength(tree)
    mean(depth[seq_len(Ntip(tree))]) - depth[getMRCA(tree, pair)]
  }, numeric(1)))
  labels <- setNames(sprintf('%s · %.1f Ma', ages$method, ages$age), ages$method)
  labels <- c(labels, Bounds = sprintf('Current bounds · %g–%g Ma', cal$min_ma, cal$max_ma))
  window <- range(c(windows[[id]], data$age_ma, ages$age, cal$min_ma, cal$max_ma), na.rm = TRUE)
  d <- density(data$age_ma, from = window[1], to = window[2], n = 512)
  curve <- data.frame(age_ma = d$x, density = d$y)
  ymax <- max(d$y)
  band <- subset(periods, older > window[1] & younger < window[2])
  band$xmin <- pmax(band$younger, window[1]); band$xmax <- pmin(band$older, window[2])
  band$label <- ifelse((band$xmax - band$xmin) / diff(window) >= .095, band$period, '')
  p <- ggplot() +
    geom_area(data = curve, aes(x = age_ma, y = density), fill = '#ABB6BF', alpha = .35) +
    geom_line(data = curve, aes(x = age_ma, y = density), color = '#8A9299', linewidth = .5) +
    geom_segment(data = data, aes(x = age_ma, xend = age_ma, y = 0, yend = .035 * ymax),
                 color = '#555555', alpha = .65, linewidth = .45) +
    geom_vline(data = data.frame(age = c(cal$min_ma, cal$max_ma)),
               aes(xintercept = age, color = 'Bounds', linetype = 'Bounds'), linewidth = .6) +
    geom_vline(data = ages, aes(xintercept = age, color = method, linetype = method), linewidth = .8) +
    geom_rect(data = band, aes(xmin = xmin, xmax = xmax, fill = colour),
              ymin = -.18 * ymax, ymax = -.05 * ymax, color = 'white', linewidth = .3) +
    geom_text(data = band, aes(x = (xmin + xmax) / 2, y = -.115 * ymax, label = label),
              size = 2.6, color = '#4C5550') +
    scale_fill_identity() +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A'),
                       breaks = names(labels), labels = labels) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'longdash', Bounds = 'dotted'),
                          breaks = names(labels), labels = labels) +
    labs(title = plots[[id]][1], x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    coord_cartesian(xlim = window, ylim = c(-.2 * ymax, ymax * 1.55), clip = 'off') +
    theme_classic(base_size = 11) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title = element_text(size = 17, margin = margin(b = 14)),
          legend.position = 'inside',
          legend.position.inside = if (id == 'CAL028') c(.03, .55) else c(.03, .97),
          legend.justification = c(0, 1), legend.background = element_blank(),
          legend.direction = 'vertical', legend.text = element_text(size = 8),
          legend.key.height = unit(13, 'pt'),
          plot.margin = margin(16, 18, 8, 12))
  ggsave(file.path(root, 'calibrations', plots[[id]][2]), p, width = 8, height = 5, dpi = 300, bg = 'white')
  cat(id, nrow(data), 'estimates;', paste(sprintf('%s %.1f', ages$method, ages$age), collapse = ', '), '\n')
}
