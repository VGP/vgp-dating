# Plot TimeTree estimates against the released MD-CAT trees and current bounds.
# Run from any directory: Rscript calibrations/plot_checkpoints.R
checkpoint_outlier <- function(ages) {
  q <- quantile(ages, c(.25, .75), na.rm = TRUE)
  spread <- q[2] - q[1]
  ages < q[1] - 1.5 * spread | ages > q[2] + 1.5 * spread
}
unbounded_pairs <- list(
  Neognathae = c('GCF_016700215.2', 'GCF_027579445.1'),
  Actinopterygii = c('GCF_900747795.2', 'GCF_901000725.2'),
  Neopterygii = c('GCF_036373705.1', 'GCF_901000725.2'),
  Sarcopterygii = c('GCF_037176945.1', 'GCF_027579445.1'))

# Sourcing this file provides the shared pairs without generating individual plots.
if (sys.nframe() == 0L) {
suppressPackageStartupMessages({ library(ape); library(ggplot2); library(patchwork); library(rphylopic) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
icons <- readRDS(file.path(root, 'calibrations/checkpoint_phylopics.rds'))
panel_icons <- list(
  CAL006 = c('lamprey', 'Lamprey', .79),
  CAL025 = c('shark', 'Shark', .18),
  Actinopterygii = c('bichir', 'Bichir', .18),
  Neopterygii = c('gar', 'Gar', .18),
  CAL009 = c('zebrafish', 'Zebrafish', .18),
  Sarcopterygii = c('eusthenopteron', 'Eusthenopteron', .18),
  CAL028 = c('ichthyostega', 'Ichthyostega', .18),
  CAL031 = c('archaeopteryx', 'Archaeopteryx', .78),
  CAL043 = c('kangaroo', 'Kangaroo', .78),
  CAL044 = c('elephant', 'Elephant', .78))
plots <- list(
  CAL005 = c('Vertebrata', 'vertebrates/vertebrata_likelihood_checkpoints.png'),
  CAL009 = c('Teleostei', 'fishes/teleostei_likelihood_checkpoints.png'),
  CAL028 = c('Tetrapoda', 'tetrapods/tetrapoda_likelihood_checkpoints.png'),
  CAL040 = c('Mammalia', 'mammals/mammalia_likelihood_checkpoints.png'),
  CAL043 = c('Marsupialia', 'mammals/marsupialia_likelihood_checkpoints.png'),
  CAL006 = c('Cyclostomata', 'vertebrates/cyclostomata_likelihood_checkpoints.png'),
  CAL007 = c('Gnathostomata', 'vertebrates/gnathostomata_likelihood_checkpoints.png'),
  CAL008 = c('Osteichthyes', 'vertebrates/osteichthyes_likelihood_checkpoints.png'),
  CAL025 = c('Chondrichthyes', 'fishes/chondrichthyes_likelihood_checkpoints.png'),
  CAL029 = c('Amniota', 'tetrapods/amniota_likelihood_checkpoints.png'),
  CAL030 = c('Sauria', 'tetrapods/sauria_likelihood_checkpoints.png'),
  CAL031 = c('Archosauria', 'tetrapods/archosauria_likelihood_checkpoints.png'),
  CAL041 = c('Theria', 'mammals/theria_likelihood_checkpoints.png'),
  CAL044 = c('Placentalia', 'mammals/placentalia_likelihood_checkpoints.png'),
  CAL002 = c('Ambulacraria', 'outgroups/ambulacraria_likelihood_checkpoints.png'),
  CAL003 = c('Chordata', 'outgroups/chordata_likelihood_checkpoints.png'),
  Neognathae = c('Neognathae', 'birds/neognathae_likelihood_checkpoints.png'),
  Actinopterygii = c('Actinopterygii', 'fishes/actinopterygii_likelihood_checkpoints.png'),
  Neopterygii = c('Neopterygii', 'fishes/neopterygii_likelihood_checkpoints.png'),
  Sarcopterygii = c('Sarcopterygii', 'tetrapods/sarcopterygii_likelihood_checkpoints.png')
)
windows <- list(CAL005 = c(400, 850), CAL009 = c(0, 400),
                CAL028 = c(200, 500), CAL040 = c(50, 300),
                CAL006 = c(200, 750), CAL007 = c(300, 700), CAL008 = c(200, 600), CAL025 = c(250, 550),
                CAL029 = c(100, 500), CAL030 = c(150, 400), CAL031 = c(150, 400),
                CAL041 = c(50, 300), CAL043 = c(0, 300), CAL044 = c(0, 200),
                CAL002 = c(400, 1050), CAL003 = c(400, 1050),
                Neognathae = c(0, 230), Actinopterygii = c(200, 500),
                Neopterygii = c(100, 450), Sarcopterygii = c(250, 500))
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
panel_groups <- list(
  c('CAL005', 'CAL006', 'CAL007', 'CAL008'),
  c('CAL025', 'Actinopterygii', 'Neopterygii', 'CAL009'),
  c('Sarcopterygii', 'CAL028', 'CAL029', 'CAL030', 'CAL031'),
  c('CAL040', 'CAL041', 'CAL043', 'CAL044'),
  c('CAL002', 'CAL003'))
for (group in panel_groups) {
  clades <- vapply(plots[group], `[`, character(1), 1)
  group_bounds <- unlist(windows[group])
  group_ages <- estimates$age_ma[estimates$clade %in% clades]
  group_cals <- master[master$calibration_id %in% group, c('min_ma', 'max_ma')]
  tree_ages <- unlist(lapply(group, function(id) {
    pair <- if (id %in% names(unbounded_pairs)) unbounded_pairs[[id]] else {
      cal <- master[master$calibration_id == id, ]
      c(cal$taxon1_accession, cal$taxon2_accession)
    }
    vapply(trees, function(tree) {
      if (!all(pair %in% tree$tip.label)) return(NA_real_)
      depth <- node.depth.edgelength(tree)
      mean(depth[seq_len(Ntip(tree))]) - depth[getMRCA(tree, pair)]
    }, numeric(1))
  }))
  shared_window <- range(c(group_bounds, group_ages, unlist(group_cals), tree_ages), na.rm = TRUE)
  for (id in group) windows[[id]] <- shared_window
}
requested <- commandArgs(trailingOnly = TRUE)
panel_cache <- list()
for (id in if (length(requested)) intersect(names(plots), requested) else names(plots)) {
  cal <- if (id %in% names(unbounded_pairs))
    data.frame(taxon1_accession = unbounded_pairs[[id]][1], taxon2_accession = unbounded_pairs[[id]][2],
               min_ma = NA_real_, max_ma = NA_real_) else master[master$calibration_id == id, ]
  data <- estimates[estimates$clade == plots[[id]][1], ]
  stopifnot(nrow(cal) == 1, nrow(data) > 1, all(is.finite(data$age_ma)))
  data$outlier <- checkpoint_outlier(data$age_ma)
  pair <- c(cal$taxon1_accession, cal$taxon2_accession)
  ages <- do.call(rbind, lapply(names(trees), function(method) {
    tree <- trees[[method]]
    if (!all(pair %in% tree$tip.label)) return(NULL)
    depth <- node.depth.edgelength(tree)
    data.frame(method = method, age = mean(depth[seq_len(Ntip(tree))]) - depth[getMRCA(tree, pair)])
  }))
  stopifnot(nrow(ages) > 0)
  labels <- setNames(sprintf('%s · %.1f Ma', ages$method, ages$age), ages$method)
  bounds <- c(cal$min_ma, cal$max_ma)
  if (all(is.finite(bounds))) labels <- c(labels, Bounds = sprintf('Current bounds · %g–%g Ma', bounds[1], bounds[2]))
  window <- range(c(windows[[id]], data$age_ma, ages$age, cal$min_ma, cal$max_ma), na.rm = TRUE)
  d <- density(data$age_ma[!data$outlier], from = window[1], to = window[2], n = 512)
  curve <- data.frame(age_ma = d$x, density = d$y)
  ymax <- max(d$y)
  band <- subset(periods, older > window[1] & younger < window[2])
  band$xmin <- pmax(band$younger, window[1]); band$xmax <- pmin(band$older, window[2])
  band$label <- ifelse((band$xmax - band$xmin) / diff(window) >= .095, band$period, '')
  p <- local({
    ymax <- ymax
    ggplot() +
    geom_area(data = curve, aes(x = age_ma, y = density), fill = '#ABB6BF', alpha = .35) +
    geom_line(data = curve, aes(x = age_ma, y = density), color = '#8A9299', linewidth = .5) +
    geom_segment(data = data, aes(x = age_ma, xend = age_ma, y = 0, yend = .035 * ymax),
                 color = ifelse(data$outlier, '#B76A61', '#555555'), alpha = .65, linewidth = .45) +
    geom_segment(data = data.frame(age = bounds[is.finite(bounds)]),
                 aes(x = age, xend = age, color = 'Bounds', linetype = 'Bounds'),
                 y = -.2 * ymax, yend = 1.12 * ymax, linewidth = .6, key_glyph = 'path') +
    geom_segment(data = ages, aes(x = age, xend = age, color = method, linetype = method),
                 y = -.2 * ymax, yend = 1.12 * ymax, linewidth = .8, key_glyph = 'path') +
    geom_rect(data = band, aes(xmin = xmin, xmax = xmax, fill = colour),
              ymin = -.18 * ymax, ymax = -.05 * ymax, color = 'white', linewidth = .3) +
    geom_text(data = band, aes(x = (xmin + xmax) / 2, y = -.115 * ymax, label = label),
              size = 2.1, color = '#4C5550') +
    scale_fill_identity() +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A'),
                       breaks = names(labels), labels = labels) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'dashed', Bounds = 'dotted'),
                          breaks = names(labels), labels = labels) +
    labs(title = plots[[id]][1], x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    coord_cartesian(xlim = window, ylim = c(-.2 * ymax, ymax * 1.55), expand = FALSE, clip = 'off') +
    theme_classic(base_size = 11) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title = element_text(size = 17, margin = margin(b = 14)),
          legend.position = 'inside',
          legend.position.inside = if (id %in% c('CAL002', 'CAL003', 'CAL005', 'CAL007', 'CAL009', 'CAL030', 'CAL031', 'CAL041', 'CAL044')) c(.97, .97) else c(.03, .97),
          legend.justification = if (id %in% c('CAL002', 'CAL003', 'CAL005', 'CAL007', 'CAL009', 'CAL030', 'CAL031', 'CAL041', 'CAL044')) c(1, 1) else c(0, 1),
          legend.background = element_blank(),
          legend.direction = 'vertical', legend.text = element_text(size = 8),
          legend.key.height = unit(13, 'pt'), legend.key.width = unit(20, 'pt'),
          plot.margin = margin(16, 18, 8, 12))
  })
  if (id %in% names(panel_icons)) {
    icon <- panel_icons[[id]]
    icon_x <- window[1] + as.numeric(icon[3]) * diff(window)
    p <- p + add_phylopic(img = icons[[icon[1]]], x = icon_x, y = .58 * ymax,
                           width = .16 * diff(window), fill = '#9BA4A0', alpha = .7) +
      annotate('text', x = icon_x, y = .82 * ymax, label = icon[2],
               size = 2.3, fontface = 'italic', color = '#777777')
  }
  ggsave(file.path(root, 'calibrations', plots[[id]][2]), p, width = 8, height = 5, dpi = 300, bg = 'white')
  panel_cache[[id]] <- p + theme(plot.title = element_text(size = 11, margin = margin(b = 8)),
                                 legend.text = element_text(size = 7),
                                 axis.text.x = element_text(size = 8), axis.title.x = element_text(size = 9))
  cat(id, nrow(data), 'estimates;', paste(sprintf('%s %.1f', ages$method, ages$age), collapse = ', '), '\n')
}
if (!length(requested)) {
  # Preserve the established deuterostome panel, including its credited silhouettes.
  deuterostome <- png::readPNG(file.path(root, 'calibrations/outgroups/deuterostomia_ages_density.png'))
  panel_cache[['CAL001']] <- wrap_elements(full = grid::rasterGrob(deuterostome, interpolate = TRUE))
  groups <- list(
    'outgroups/outgroups_likelihood_checkpoints.png' = c('CAL001', 'CAL002', 'CAL003'),
    'vertebrates/vertebrates_likelihood_checkpoints.png' = c('CAL005', 'CAL006', 'CAL007', 'CAL008'),
    'fishes/fishes_likelihood_checkpoints.png' = c('CAL025', 'Actinopterygii', 'Neopterygii', 'CAL009'),
    'tetrapods/tetrapods_likelihood_checkpoints.png' = c('Sarcopterygii', 'CAL028', 'CAL029', 'CAL030', 'CAL031'),
    'mammals/mammals_likelihood_checkpoints.png' = c('CAL040', 'CAL041', 'CAL043', 'CAL044'))
  for (path in names(groups)) {
    ids <- groups[[path]]; stopifnot(all(ids %in% names(panel_cache)))
    ncol <- if (length(ids) == 3) 3 else if (length(ids) == 4) 2 else 3
    figure <- if (length(ids) == 5) {
      wrap_plots(panel_cache[ids[1:3]], ncol = 3) /
        (plot_spacer() + panel_cache[[ids[4]]] + panel_cache[[ids[5]]] + plot_spacer() +
           plot_layout(widths = c(.5, 1, 1, .5)))
    } else wrap_plots(panel_cache[ids], ncol = ncol)
    ggsave(file.path(root, 'calibrations', path), figure,
           width = 5 * ncol, height = 3.5 * ceiling(length(ids) / ncol), dpi = 300, bg = 'white')
  }
}
}
