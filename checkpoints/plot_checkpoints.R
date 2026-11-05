# Plot published estimates against the released MD-CAT trees and current bounds.
# Run from any directory: Rscript checkpoints/plot_checkpoints.R
checkpoint_outlier <- function(ages) {
  q <- quantile(ages, c(.25, .75), na.rm = TRUE)
  spread <- q[2] - q[1]
  ages < q[1] - 1.5 * spread | ages > q[2] + 1.5 * spread
}
unbounded_pairs <- list(
  Neognathae = c('GCF_016700215.2', 'GCF_027579445.1'),
  Actinopterygii = c('GCF_900747795.2', 'GCF_901000725.2'),
  Neopterygii = c('GCF_036373705.1', 'GCF_901000725.2'),
  Actinopteri = c('GCF_902713425.1', 'GCF_901000725.2'),
  Holostei = c('GCF_036373705.1', 'GCF_040954835.1'),
  Elasmobranchii = c('GCF_017639515.1', 'GCA_963514005.1'),
  Archelosauria = c('GCF_030867095.1', 'GCA_965140285.1'),
  Sarcopterygii = c('GCF_037176945.1', 'GCF_027579445.1'),
  Gymnophiona = c('GCF_901001135.1', 'GCA_901765095.2'),
  Aves = c('GCF_040807025.1', 'GCF_016700215.2'),
  Palaeognathae = c('GCF_040807025.1', 'GCA_047922985.1'),
  Neoaves = c('GCA_009819775.1', 'GCF_027579445.1'))

# Sourcing this file provides the shared pairs without generating individual plots.
if (sys.nframe() == 0L) {
suppressPackageStartupMessages({ library(ape); library(ggplot2); library(patchwork) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'checkpoints/checkpoint_estimates.csv'))
plots <- list(
  CAL001 = c('Deuterostomia', 'outgroups/deuterostomia_ages_density.png'),
  CAL005 = c('Vertebrata', 'vertebrates/vertebrata_likelihood_checkpoints.png'),
  CAL009 = c('Teleostei', 'fishes/teleostei_likelihood_checkpoints.png'),
  CAL028 = c('Tetrapoda', 'tetrapods/tetrapoda_likelihood_checkpoints.png'),
  CAL032 = c('Lissamphibia', 'amphibia/lissamphibia_likelihood_checkpoints.png'),
  CAL033 = c('Batrachia', 'amphibia/batrachia_likelihood_checkpoints.png'),
  CAL034 = c('Anura', 'amphibia/anura_likelihood_checkpoints.png'),
  Gymnophiona = c('Gymnophiona', 'amphibia/gymnophiona_likelihood_checkpoints.png'),
  CAL064 = c('Squamata', 'squamata/squamata_likelihood_checkpoints.png'),
  CAL074 = c('Testudines', 'turtles/testudines_timetree_estimates.png'),
  CAL083 = c('Crocodylia', 'crocodylia/crocodylia_calibrations.png'),
  Aves = c('Aves', 'birds/aves_checkpoint.png'),
  Palaeognathae = c('Palaeognathae', 'birds/palaeognathae_checkpoint.png'),
  CAL084 = c('Galloanserae', 'birds/galloanserae_checkpoint.png'),
  Neoaves = c('Neoaves', 'birds/neoaves_checkpoint.png'),
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
  Actinopteri = c('Actinopteri', 'fishes/actinopteri_likelihood_checkpoints.png'),
  Holostei = c('Holostei', 'fishes/holostei_likelihood_checkpoints.png'),
  Elasmobranchii = c('Elasmobranchii', 'fishes/elasmobranchii_likelihood_checkpoints.png'),
  Archelosauria = c('Archelosauria', 'tetrapods/archelosauria_likelihood_checkpoints.png'),
  Sarcopterygii = c('Sarcopterygii', 'tetrapods/sarcopterygii_likelihood_checkpoints.png')
)
windows <- list(CAL001 = c(450, 1050), CAL005 = c(400, 850), CAL009 = c(0, 400),
                CAL032 = c(0, 400), CAL033 = c(0, 400), CAL034 = c(0, 400), Gymnophiona = c(0, 400),
                CAL064 = c(100, 300), CAL074 = c(50, 300), CAL083 = c(0, 200),
                Aves = c(0, 260), Palaeognathae = c(0, 260), CAL084 = c(0, 260), Neoaves = c(0, 260),
                CAL028 = c(200, 500), CAL040 = c(50, 300),
                CAL006 = c(200, 750), CAL007 = c(300, 700), CAL008 = c(200, 600), CAL025 = c(250, 550),
                CAL029 = c(100, 500), CAL030 = c(150, 400), CAL031 = c(150, 400),
                CAL041 = c(50, 300), CAL043 = c(0, 300), CAL044 = c(0, 200),
                CAL002 = c(400, 1050), CAL003 = c(400, 1050),
                Neognathae = c(0, 230), Actinopterygii = c(200, 500),
                Neopterygii = c(100, 450), Actinopteri = c(100, 450), Holostei = c(100, 450),
                Elasmobranchii = c(100, 450), Archelosauria = c(150, 400), Sarcopterygii = c(250, 500))
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
  c('CAL001', 'CAL002', 'CAL003'),
  c('CAL005', 'CAL006', 'CAL007', 'CAL008'),
  c('CAL025', 'Elasmobranchii', 'Actinopterygii', 'Actinopteri', 'Neopterygii', 'Holostei', 'CAL009'),
  c('Sarcopterygii', 'CAL028', 'CAL029', 'CAL030', 'Archelosauria', 'CAL031'),
  c('CAL040', 'CAL041', 'CAL043', 'CAL044'),
  c('CAL032', 'CAL033', 'CAL034', 'Gymnophiona'),
  c('Aves', 'Palaeognathae', 'Neognathae', 'CAL084', 'Neoaves'))
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
  padding <- max(vapply(clades, function(clade) {
    v <- estimates$age_ma[estimates$clade == clade]; 3 * bw.nrd0(v[!checkpoint_outlier(v)])
  }, numeric(1)), na.rm = TRUE)
  shared_window <- c(max(0, shared_window[1] - padding), shared_window[2] + padding)
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
  if (all(is.finite(bounds))) labels <- c(labels, Bounds = sprintf('Bounds · %g–%g Ma', bounds[1], bounds[2]))
  retained <- data$age_ma[!data$outlier]
  tails <- range(retained) + c(-3, 3) * bw.nrd0(retained)
  window <- range(c(windows[[id]], data$age_ma, ages$age, cal$min_ma, cal$max_ma, tails), na.rm = TRUE)
  d <- density(data$age_ma[!data$outlier], from = window[1], to = window[2], n = 512)
  curve <- data.frame(age_ma = d$x, density = d$y)
  ymax <- max(d$y)
  oxfordian <- NULL
  if (id == 'CAL074') {
    older <- retained[retained >= 157.3]
    older <- older[!checkpoint_outlier(older)]
    od <- density(older, from = window[1], to = window[2], n = 512)
    oxfordian <- data.frame(age_ma = od$x, density = od$y)
    ymax <- max(ymax, od$y)
    labels <- c(labels, Published = 'All estimates', Oxfordian = 'Oxfordian or older (≥157.3 Ma)')
  }
  # Choose the side with the fewest vertical markers and the lowest density.
  # Both the curve and markers must remain visible behind the in-panel key.
  key_score <- vapply(c('left', 'right'), function(side) {
    span <- window[1] + diff(window) * if (side == 'left') c(.03, .47) else c(.53, .97)
    markers <- c(ages$age, bounds[is.finite(bounds)])
    height <- max(c(0, curve$density[curve$age_ma >= span[1] & curve$age_ma <= span[2]])) / ymax
    10 * sum(markers >= span[1] & markers <= span[2]) + height
  }, numeric(1))
  key_right <- key_score['right'] < key_score['left']
  band <- subset(periods, older > window[1] & younger < window[2])
  band$xmin <- pmax(band$younger, window[1]); band$xmax <- pmin(band$older, window[2])
  band$label <- ifelse((band$xmax - band$xmin) / diff(window) >= .095, band$period, '')
  band$label[band$label == 'Carboniferous'] <- 'Carbonif.'
  p <- local({
    ymax <- ymax
    ggplot() +
    geom_area(data = curve, aes(x = age_ma, y = density), fill = '#ABB6BF', alpha = .35) +
    {if (is.null(oxfordian)) geom_line(data = curve, aes(x = age_ma, y = density), color = '#8A9299', linewidth = .5)
     else list(
       geom_line(data = curve, aes(x = age_ma, y = density, color = 'Published', linetype = 'Published'), linewidth = .5),
       geom_area(data = oxfordian, aes(x = age_ma, y = density), fill = '#C4C3AF', alpha = .4),
       geom_line(data = oxfordian, aes(x = age_ma, y = density, color = 'Oxfordian', linetype = 'Oxfordian'), linewidth = .6))} +
    geom_segment(data = data, aes(x = age_ma, xend = age_ma, y = 0, yend = .035 * ymax),
                 color = ifelse(data$outlier | (id == 'CAL074' & data$age_ma < 157.3), '#B76A61', '#555555'), alpha = .65, linewidth = .45) +
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
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A', Published = '#8A9299', Oxfordian = '#77786D'),
                       breaks = names(labels), labels = labels) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'dashed', Bounds = 'dotted', Published = 'solid', Oxfordian = 'solid'),
                          breaks = names(labels), labels = labels) +
    labs(title = plots[[id]][1], x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    coord_cartesian(xlim = window, ylim = c(-.2 * ymax, ymax * 1.2), expand = FALSE, clip = 'off') +
    theme_classic(base_size = 11) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title = element_text(size = 17, margin = margin(b = 4)),
          legend.position = 'inside',
          legend.position.inside = if (key_right) c(.97, .97) else c(.03, .97),
          legend.justification = if (key_right) c(1, 1) else c(0, 1),
          legend.background = element_blank(),
          legend.direction = 'vertical', legend.text = element_text(size = 9),
          legend.key.height = unit(10, 'pt'), legend.key.width = unit(17, 'pt'),
          plot.margin = margin(8, 18, 8, 12))
  })
  if (length(requested) || id %in% c('CAL064', 'CAL074', 'CAL083'))
    ggsave(file.path(root, 'calibrations', plots[[id]][2]), p, width = 8, height = 5, dpi = 300, bg = 'white')
  panel_cache[[id]] <- p + theme(plot.title = element_text(size = 11, margin = margin(b = 4)),
                                 legend.text = element_text(size = 8),
                                 axis.text.x = element_text(size = 8), axis.title.x = element_text(size = 9))
  cat(id, nrow(data), 'estimates;', paste(sprintf('%s %.1f', ages$method, ages$age), collapse = ', '), '\n')
}
if (!length(requested)) {
  groups <- list(
    'outgroups/outgroups_likelihood_checkpoints.png' = c('CAL001', 'CAL002', 'CAL003'),
    'vertebrates/vertebrates_likelihood_checkpoints.png' = c('CAL005', 'CAL006', 'CAL007', 'CAL008'),
    'fishes/fishes_likelihood_checkpoints.png' = c('CAL025', 'Elasmobranchii', 'Actinopterygii', 'Actinopteri', 'Neopterygii', 'Holostei', 'CAL009'),
    'tetrapods/tetrapods_likelihood_checkpoints.png' = c('Sarcopterygii', 'CAL028', 'CAL029', 'CAL030', 'Archelosauria', 'CAL031'),
    'mammals/mammals_likelihood_checkpoints.png' = c('CAL040', 'CAL041', 'CAL043', 'CAL044'),
    'amphibia/amphibia_likelihood_checkpoints.png' = c('CAL032', 'CAL033', 'CAL034', 'Gymnophiona'),
    'birds/aves_likelihood_checkpoints.png' = c('Aves', 'Palaeognathae', 'Neognathae', 'CAL084', 'Neoaves'))
  for (path in names(groups)) {
    ids <- groups[[path]]; stopifnot(all(ids %in% names(panel_cache)))
    ncol <- 2
    panels <- panel_cache[ids]
    empty_slots <- (ncol - length(panels) %% ncol) %% ncol
    if (empty_slots) panels <- c(panels, replicate(empty_slots, plot_spacer(), simplify = FALSE))
    figure <- wrap_plots(panels, ncol = ncol)
    ggsave(file.path(root, 'calibrations', path), figure,
           width = 5 * ncol, height = 3.5 * ceiling(length(ids) / ncol), dpi = 300, bg = 'white')
  }
}

# Compact overview
ids <- c(Deuterostomia = 'CAL001', Ambulacraria = 'CAL002', Chordata = 'CAL003',
         Vertebrata = 'CAL005', Teleostei = 'CAL009',
         Tetrapoda = 'CAL028', Lissamphibia = 'CAL032', Batrachia = 'CAL033',
         Anura = 'CAL034', Gymnophiona = NA, Squamata = 'CAL064',
         Testudines = 'CAL074', Crocodylia = 'CAL083', Mammalia = 'CAL040',
         Aves = NA, Neoaves = NA, Palaeognathae = NA, Neognathae = NA, Galloanserae = 'CAL084',
         Actinopterygii = NA, Neopterygii = NA, Sarcopterygii = NA,
         Cyclostomata = 'CAL006', Gnathostomata = 'CAL007', Osteichthyes = 'CAL008',
         Chondrichthyes = 'CAL025', Amniota = 'CAL029', Sauria = 'CAL030', Archosauria = 'CAL031',
         Theria = 'CAL041', Marsupialia = 'CAL043', Placentalia = 'CAL044',
         Actinopteri = NA, Holostei = NA, Elasmobranchii = NA, Archelosauria = NA)
tree_files <- c(ROADIES = 'roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre',
                ASTRAL = 'astralpro.l6p1/astralpro.l6p1.independent.fast95.tre')
trees <- lapply(file.path(root, 'dating/mdcat', tree_files), function(path) {
  tree <- read.nexus(path)
  tree$tip.label <- gsub("'", '', tree$tip.label, fixed = TRUE)
  stopifnot(is.rooted(tree), is.ultrametric(tree))
  tree
})
names(trees) <- names(tree_files)
panels <- lapply(names(ids), function(clade) {
  cal <- if (clade == 'Gymnophiona') {
    data.frame(taxon1_accession = 'GCF_901001135.1', taxon2_accession = 'GCA_901765095.2',
               min_ma = NA_real_, max_ma = NA_real_)
  } else if (clade %in% names(unbounded_pairs)) {
    data.frame(taxon1_accession = unbounded_pairs[[clade]][1], taxon2_accession = unbounded_pairs[[clade]][2],
               min_ma = NA_real_, max_ma = NA_real_)
  } else if (clade == 'Neoaves') {
    data.frame(taxon1_accession = 'GCA_009819775.1', taxon2_accession = 'GCF_027579445.1',
               min_ma = NA_real_, max_ma = NA_real_)
  } else if (clade %in% c('Aves', 'Palaeognathae')) {
    data.frame(taxon1_accession = 'GCF_040807025.1',
      taxon2_accession = if (clade == 'Aves') 'GCF_016700215.2' else 'GCA_047922985.1',
      min_ma = NA_real_, max_ma = NA_real_)
  } else master[master$calibration_id == ids[[clade]], ]
  values <- estimates[estimates$clade == clade & is.finite(estimates$age_ma), ]
  stopifnot(nrow(cal) == 1, nrow(values) > 1)
  values$outlier <- checkpoint_outlier(values$age_ma)
  if (clade == 'Testudines') {
    values$outlier <- values$outlier | values$age_ma < 157.3
    older <- which(!values$outlier)
    values$outlier[older] <- checkpoint_outlier(values$age_ma[older])
  }
  pair <- c(cal$taxon1_accession, cal$taxon2_accession)
  node_ages <- lapply(names(trees), function(method) {
    tree <- trees[[method]]
    if (!all(pair %in% tree$tip.label)) return(NULL)
    depth <- node.depth.edgelength(tree)
    data.frame(method = method, age = mean(depth[seq_len(Ntip(tree))]) - depth[getMRCA(tree, pair)])
  })
  node_ages <- do.call(rbind, node_ages)
  # The first panel lacks the ASTRAL outgroups, but its shared key still needs both trees.
  if (clade == 'Deuterostomia') node_ages <- rbind(node_ages, data.frame(method = 'ASTRAL', age = NA_real_))
  window <- range(c(values$age_ma[!values$outlier], cal$min_ma, cal$max_ma, node_ages$age), na.rm = TRUE)
  padding <- max(.12 * diff(window), 2 * bw.nrd0(values$age_ma[!values$outlier]))
  window <- window + c(-1, 1) * padding
  window[1] <- max(0, window[1])
  ticks <- pretty(window, n = 4)
  ticks <- ticks[ticks >= window[1] & ticks <= window[2]]
  if (length(ticks) < 2) ticks <- signif(window, 3)
  d <- density(values$age_ma[!values$outlier], from = window[1], to = window[2], n = 512)
  curve <- data.frame(age = d$x, density = d$y)
  ymax <- max(d$y)
  panel_top <- if (clade == 'Deuterostomia') 2.1 else 1.3
  key_breaks <- if (is.finite(cal$min_ma) || is.finite(cal$max_ma)) c('ROADIES', 'ASTRAL', 'Bounds') else c('ROADIES', 'ASTRAL')
  p <- ggplot() +
    geom_area(data = curve, aes(x = age, y = density), fill = '#ABB6BF', alpha = .35) +
    geom_line(data = curve, aes(x = age, y = density), color = '#8A9299', linewidth = .4) +
    geom_segment(data = values, aes(x = age_ma, xend = age_ma, y = 0, yend = .045 * ymax),
                 color = ifelse(values$outlier, '#B76A61', '#555555'), alpha = .8, linewidth = .3) +
    geom_segment(data = data.frame(age = c(cal$min_ma, cal$max_ma)[is.finite(c(cal$min_ma, cal$max_ma))]),
                 aes(x = age, xend = age, color = 'Bounds', linetype = 'Bounds'),
                 y = 0, yend = 1.08 * ymax, linewidth = .4, key_glyph = 'path') +
    geom_segment(data = node_ages, aes(x = age, xend = age, color = method, linetype = method),
                 y = 0, yend = 1.08 * ymax, linewidth = .6, key_glyph = 'path', show.legend = TRUE, na.rm = TRUE) +
    annotate('text', x = window[1] + .02 * diff(window), y = (panel_top - .04) * ymax,
             label = clade, hjust = 0, vjust = 1, size = 2.3) +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A'),
                       breaks = key_breaks, drop = FALSE) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'dashed', Bounds = 'dotted'),
                          breaks = key_breaks, drop = FALSE) +
    scale_x_continuous(breaks = ticks) +
    coord_cartesian(xlim = window, ylim = c(0, ymax * panel_top)) +
    labs(x = NULL, y = NULL, color = NULL, linetype = NULL) +
    theme_classic(base_size = 5.5) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          axis.text.x = element_text(size = 5),
          legend.position = 'none',
          axis.ticks.length = unit(2, 'pt'), plot.margin = margin(3, 4, 3, 3))
  if (clade == 'Deuterostomia') p <- p + theme(
    legend.position = 'inside', legend.position.inside = c(.44, .84),
    legend.justification = c(0, 1), legend.direction = 'vertical',
    legend.background = element_blank(), legend.key = element_blank(),
    legend.text = element_text(size = 5), legend.key.width = unit(12, 'pt'),
    legend.key.height = unit(7, 'pt'))
  p
})
names(panels) <- names(ids)
# Read left-to-right, top-to-bottom: deep splits followed by related vertebrate groups.
order <- c('Deuterostomia', 'Ambulacraria', 'Chordata', 'Vertebrata', 'Cyclostomata', 'Gnathostomata',
           'Chondrichthyes', 'Elasmobranchii', 'Osteichthyes', 'Actinopterygii', 'Actinopteri', 'Neopterygii',
           'Holostei', 'Teleostei', 'Sarcopterygii', 'Tetrapoda', 'Lissamphibia', 'Gymnophiona',
           'Batrachia', 'Anura', 'Amniota', 'Mammalia', 'Theria', 'Marsupialia',
           'Placentalia', 'Sauria', 'Squamata', 'Archelosauria', 'Testudines', 'Archosauria',
           'Crocodylia', 'Aves', 'Palaeognathae', 'Neognathae', 'Galloanserae', 'Neoaves')
stopifnot(length(order) == length(ids), setequal(order, names(ids)))
figure <- wrap_plots(panels[order], ncol = 6)
pdf(NULL)
figure <- grid::grobTree(patchwork::patchworkGrob(figure),
                         grid::textGrob('Age (Ma)', x = .5, y = grid::unit(1, 'mm'),
                                        just = c('centre', 'bottom'), gp = grid::gpar(fontsize = 5)))
dev.off()
ggsave(file.path(root, 'checkpoints/checkpoints_summary.png'), figure,
       width = 180, height = 170, units = 'mm', dpi = 600, bg = 'white')
ggsave(file.path(root, 'checkpoints/checkpoints_summary.pdf'), figure,
       width = 180, height = 170, units = 'mm', device = cairo_pdf, bg = 'white')

}
