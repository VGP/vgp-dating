# Compact overview of the published checkpoint estimates and released trees.
# Run from any directory: Rscript calibrations/plot_checkpoint_summary.R
suppressPackageStartupMessages({ library(ape); library(ggplot2); library(patchwork) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
source(file.path(root, 'calibrations/plot_checkpoints.R'), local = TRUE)
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
ids <- c(Deuterostomia = 'CAL001', Ambulacraria = 'CAL002', Chordata = 'CAL003',
         Vertebrata = 'CAL005', Teleostei = 'CAL009',
         Tetrapoda = 'CAL028', Lissamphibia = 'CAL032', Batrachia = 'CAL033',
         Anura = 'CAL034', Gymnophiona = NA, Squamata = 'CAL064',
         Testudines = 'CAL074', Crocodylia = 'CAL083', Mammalia = 'CAL040',
         Aves = NA, Neoaves = NA, Palaeognathae = NA, Neognathae = NA,
         Actinopterygii = NA, Neopterygii = NA, Sarcopterygii = NA,
         Cyclostomata = 'CAL006', Gnathostomata = 'CAL007', Osteichthyes = 'CAL008',
         Chondrichthyes = 'CAL025', Amniota = 'CAL029', Sauria = 'CAL030', Archosauria = 'CAL031',
         Theria = 'CAL041', Marsupialia = 'CAL043', Placentalia = 'CAL044')
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
  panel_top <- if (clade == 'Deuterostomia') 1.65 else 1.3
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
          legend.position = 'none',
          axis.ticks.length = unit(2, 'pt'), plot.margin = margin(3, 4, 3, 3))
  if (clade == 'Deuterostomia') p <- p + theme(
    legend.position = 'inside', legend.position.inside = c(.53, .98),
    legend.justification = c(0, 1), legend.direction = 'vertical',
    legend.background = element_blank(), legend.key = element_blank(),
    legend.text = element_text(size = 5), legend.key.width = unit(12, 'pt'),
    legend.key.height = unit(7, 'pt'))
  p
})
names(panels) <- names(ids)
# Read left-to-right, top-to-bottom: deep splits followed by related vertebrate groups.
order <- c('Deuterostomia', 'Ambulacraria', 'Chordata', 'Vertebrata', 'Cyclostomata',
           'Gnathostomata', 'Chondrichthyes', 'Osteichthyes', 'Actinopterygii', 'Neopterygii',
           'Teleostei', 'Sarcopterygii', 'Tetrapoda', 'Lissamphibia', 'Gymnophiona',
           'Batrachia', 'Anura', 'Amniota', 'Mammalia', 'Theria', 'Marsupialia', 'Placentalia',
           'Sauria', 'Squamata', 'Testudines', 'Archosauria', 'Crocodylia',
           'Aves', 'Palaeognathae', 'Neognathae', 'Neoaves')
stopifnot(length(order) == length(ids), setequal(order, names(ids)))
figure <- (wrap_plots(panels[order[1:25]], ncol = 5) /
           wrap_plots(panels[order[26:31]], ncol = 6) + plot_layout(heights = c(5, 1))) +
  plot_annotation(caption = 'Age (Ma)', theme = theme(plot.caption = element_text(size = 6, hjust = .5)))
ggsave(file.path(root, 'calibrations/checkpoints_summary.png'), figure,
       width = 180, height = 170, units = 'mm', dpi = 600, bg = 'white')
ggsave(file.path(root, 'calibrations/checkpoints_summary.pdf'), figure,
       width = 180, height = 170, units = 'mm', device = cairo_pdf, bg = 'white')
