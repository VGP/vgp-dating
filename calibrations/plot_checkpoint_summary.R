# Compact overview of the published checkpoint estimates and released trees.
# Run from any directory: Rscript calibrations/plot_checkpoint_summary.R
suppressPackageStartupMessages({ library(ape); library(ggplot2); library(patchwork) })
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(normalizePath(script)))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
estimates <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
ids <- c(Deuterostomia = 'CAL001', Vertebrata = 'CAL005', Teleostei = 'CAL009',
         Tetrapoda = 'CAL028', Lissamphibia = 'CAL032', Batrachia = 'CAL033',
         Anura = 'CAL034', Gymnophiona = NA, Squamata = 'CAL064',
         Testudines = 'CAL074', Crocodylia = 'CAL083', Mammalia = 'CAL040')
windows <- list(Deuterostomia = c(480, 1050), Vertebrata = c(400, 850), Teleostei = c(0, 400),
                Tetrapoda = c(200, 500), Lissamphibia = c(200, 400), Batrachia = c(150, 400),
                Anura = c(100, 350), Gymnophiona = c(0, 400), Squamata = c(100, 320),
                Testudines = c(50, 300), Crocodylia = c(0, 200), Mammalia = c(50, 300))
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
  } else master[master$calibration_id == ids[[clade]], ]
  values <- estimates[estimates$clade == clade & is.finite(estimates$age_ma), ]
  stopifnot(nrow(cal) == 1, nrow(values) > 1)
  pair <- c(cal$taxon1_accession, cal$taxon2_accession)
  node_ages <- lapply(names(trees), function(method) {
    tree <- trees[[method]]
    if (!all(pair %in% tree$tip.label)) return(NULL)
    depth <- node.depth.edgelength(tree)
    data.frame(method = method, age = mean(depth[seq_len(Ntip(tree))]) - depth[getMRCA(tree, pair)])
  })
  node_ages <- do.call(rbind, node_ages)
  window <- range(c(windows[[clade]], values$age_ma, cal$min_ma, cal$max_ma, node_ages$age), na.rm = TRUE)
  d <- density(values$age_ma, from = window[1], to = window[2], n = 512)
  curve <- data.frame(age = d$x, density = d$y)
  ymax <- max(d$y)
  p <- ggplot() +
    geom_area(data = curve, aes(x = age, y = density), fill = '#ABB6BF', alpha = .35) +
    geom_line(data = curve, aes(x = age, y = density), color = '#8A9299', linewidth = .4) +
    geom_segment(data = values, aes(x = age_ma, xend = age_ma, y = 0, yend = .045 * ymax),
                 color = '#555555', alpha = .6, linewidth = .3) +
    geom_vline(data = data.frame(age = c(cal$min_ma, cal$max_ma)[is.finite(c(cal$min_ma, cal$max_ma))]),
               aes(xintercept = age, color = 'Bounds', linetype = 'Bounds'), linewidth = .4) +
    geom_vline(data = node_ages, aes(xintercept = age, color = method, linetype = method), linewidth = .6) +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A'),
                       breaks = c('ROADIES', 'ASTRAL', 'Bounds'), drop = FALSE) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'longdash', Bounds = 'dotted'),
                          breaks = c('ROADIES', 'ASTRAL', 'Bounds'), drop = FALSE) +
    coord_cartesian(xlim = window, ylim = c(0, ymax * 1.1)) +
    labs(title = clade, x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    theme_classic(base_size = 9) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          plot.title = element_text(size = 11), legend.position = 'bottom',
          legend.text = element_text(size = 8), plot.margin = margin(6, 8, 4, 4))
  if (clade %in% c('Deuterostomia', 'Batrachia', 'Gymnophiona')) p <- p + theme(legend.position = 'none')
  p
})
overview <- wrap_plots(panels, ncol = 3, guides = 'collect') & theme(legend.position = 'bottom')
ggsave(file.path(root, 'calibrations/checkpoints_summary.png'), overview,
       width = 12, height = 10, dpi = 250, bg = 'white')
