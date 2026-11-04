# Plot TimeTree estimates against the released MD-CAT trees and current bounds.
# Run from any directory: Rscript calibrations/plot_checkpoints.R
suppressPackageStartupMessages({ library(ape); library(ggplot2); library(rphylopic) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
plots <- list(
  CAL005 = c('Vertebrata', 'vertebrates/vertebrata_likelihood_checkpoints.png'),
  CAL009 = c('Teleostei', 'fishes/teleostei_likelihood_checkpoints.png'),
  CAL028 = c('Tetrapoda', 'tetrapods/tetrapoda_likelihood_checkpoints.png'),
  CAL040 = c('Mammalia', 'mammals/mammalia_likelihood_checkpoints.png')
)
# Public-domain silhouettes and their sources are recorded in PHYLOPIC_CREDITS.md.
icons <- list(
  CAL005 = c('cf4580eb-847f-401a-854a-3ca28eb63cd0', '545d45f0-0dd1-4cfd-aad6-2b835223ea0d', '51ee5cb2-e7fe-48f5-939a-2aad427919ec'),
  CAL009 = c('cce80cff-99d2-4642-8ceb-3936c2cc4a3e', '986a42ec-51f6-4c0e-9e62-2fcbad2657c3', 'c93f7d19-849d-4b84-beb1-ff624fc098e0'),
  CAL028 = c('ac0368c5-05ad-4b01-bf0c-c5bc7cf85203', '5170633b-b867-4c98-acc0-fbb823fc0aaa', 'e55d26b9-d7f8-4603-b71f-ab4a4a536e56', '5d59b5ce-c1dd-40f6-b295-8d2629b9775e'),
  CAL040 = c('3ca524e8-74c5-45ad-a267-9f599ab7d751', '0e1fe113-feb7-46db-8a10-12f22f80332c', '5d59b5ce-c1dd-40f6-b295-8d2629b9775e')
)
icon_labels <- list(CAL005 = c('Hagfishes', 'Sharks', 'Birds'), CAL009 = c('Tarpons', 'Sunfishes', 'Cods'),
                    CAL028 = c('Caecilians', 'Turtles', 'Birds', 'Mammals'),
                    CAL040 = c('Monotremes', 'Marsupials', 'Placentals'))
windows <- list(CAL005 = c(400, 850), CAL009 = c(0, 400),
                CAL028 = c(200, 500), CAL040 = c(50, 300))
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
for (id in names(plots)) {
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
  window <- windows[[id]]
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
  n_icons <- length(icons[[id]])
  positions <- if (n_icons == 4) c(.12, .27, .73, .88) else seq(.60, .91, length.out = n_icons)
  icon_x <- window[1] + diff(window) * positions
  icon_y <- ymax * rep(c(1.24, 1.12), length.out = n_icons)
  for (i in seq_along(icons[[id]])) p <- p + add_phylopic(
    uuid = icons[[id]][i], x = icon_x[i], y = icon_y[i], angle = rep(c(8, -6), length.out = n_icons)[i],
    width = diff(window) * .11, fill = '#B8BDBA')
  p <- p + annotate('text', x = icon_x, y = icon_y + .24 * ymax,
                    label = icon_labels[[id]], color = '#777F7B', size = 3.2)
  ggsave(file.path(root, 'calibrations', plots[[id]][2]), p, width = 8, height = 5, dpi = 300, bg = 'white')
  cat(id, nrow(data), 'estimates;', paste(sprintf('%s %.1f', ages$method, ages$age), collapse = ', '), '\n')
}
