# Bird likelihood checkpoints. Run from any directory.
suppressPackageStartupMessages({library(ape); library(ggplot2); library(patchwork); library(rphylopic)})
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
source(file.path(root, 'checkpoints/plot_checkpoints.R'), local = TRUE)
data <- read.csv(file.path(root, 'checkpoints/checkpoint_estimates.csv'))
master <- read.csv(file.path(root, 'calibrations/master_calibrations.csv'))
icons <- readRDS(file.path(root, 'checkpoints/checkpoint_phylopics.rds'))
pairs <- list(Aves = c('GCF_040807025.1', 'GCF_016700215.2'),
              Palaeognathae = c('GCF_040807025.1', 'GCA_047922985.1'),
              Neognathae = c('GCF_016700215.2', 'GCF_027579445.1'),
              Galloanserae = c('GCF_016700215.2', 'GCA_964211835.1'),
              Neoaves = c('GCA_009819775.1', 'GCF_027579445.1'))
files <- c(ROADIES = 'roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre',
           ASTRAL = 'astralpro.l6p1/astralpro.l6p1.independent.fast95.tre')
trees <- lapply(file.path(root, 'dating/mdcat', files), function(path) {
  tree <- read.nexus(path); tree$tip.label <- gsub("'", '', tree$tip.label, fixed = TRUE)
  stopifnot(is.rooted(tree), is.ultrametric(tree)); tree
})
names(trees) <- names(files)
if (!interactive()) grDevices::pdf(NULL)
ostrich <- get_phylopic(uuid = 'df5979fc-7cdd-41c7-ac47-7107ba3f7e1a')
width <- max(260, data$age_ma[data$clade %in% names(pairs)], na.rm = TRUE)
plots <- lapply(names(pairs), function(clade) {
  values <- data[data$clade == clade & is.finite(data$age_ma), ]
  stopifnot(nrow(values) > 1)
  ages <- do.call(rbind, lapply(names(trees), function(method) {
    t <- trees[[method]]; stopifnot(all(pairs[[clade]] %in% t$tip.label))
    depth <- node.depth.edgelength(t)
    data.frame(method = method, age = mean(depth[seq_len(Ntip(t))]) - depth[getMRCA(t, pairs[[clade]])])
  }))
  values$outlier <- checkpoint_outlier(values$age_ma)
  d <- density(values$age_ma[!values$outlier], from = 0, to = width, n = 512)
  curve <- data.frame(age = d$x, density = d$y); ymax <- max(d$y)
  bounds <- if (clade == 'Galloanserae') unlist(master[master$calibration_id == 'CAL084', c('min_ma', 'max_ma')], use.names = FALSE) else numeric()
  legend_labels <- c(setNames(sprintf('%s · %.1f Ma', ages$method, ages$age), ages$method),
                     if (length(bounds)) c(Bounds = sprintf('Current bounds · %g–%g Ma', bounds[1], bounds[2])))
  p <- ggplot(curve, aes(age, density)) +
    geom_area(fill = '#A2B3A8', alpha = .38) +
    geom_line(color = '#81968A', linewidth = .65) +
    geom_rug(data = subset(values, !outlier), aes(x = age_ma), inherit.aes = FALSE,
             color = '#555555', linewidth = .5, alpha = .7, length = unit(.025, 'npc')) +
    geom_rug(data = subset(values, outlier), aes(x = age_ma), inherit.aes = FALSE,
             color = '#B76A61', linewidth = .6, length = unit(.025, 'npc')) +
    geom_segment(data = ages, aes(x = age, xend = age, y = 0, yend = 1.15 * ymax,
                                  color = method, linetype = method), inherit.aes = FALSE, linewidth = .8) +
    geom_segment(data = data.frame(age = bounds), aes(x = age, xend = age, color = 'Bounds', linetype = 'Bounds'),
                 y = 0, yend = 1.15 * ymax, inherit.aes = FALSE, linewidth = .5) +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D', Bounds = '#8A8A8A'),
                       breaks = names(legend_labels), labels = legend_labels) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'dashed', Bounds = 'dotted'),
                          breaks = names(legend_labels), labels = legend_labels) +
    coord_cartesian(xlim = c(0, width), ylim = c(0, 1.55 * ymax), expand = FALSE) +
    annotate('text', x = width * .04, y = ymax * 1.45, label = clade, hjust = 0, size = 5, color = '#333333') +
    labs(x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    theme_classic(base_size = 11) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          axis.line = element_line(color = '#777777', linewidth = .4),
          legend.position = 'inside', legend.position.inside = c(.04, .86),
          legend.justification = c(0, 1), legend.direction = 'vertical',
          legend.background = element_blank(), legend.key = element_blank(),
          legend.key.width = unit(20, 'pt'), legend.key.height = unit(12, 'pt'),
          legend.text = element_text(size = 8, color = '#555555'),
          plot.margin = margin(12, 14, 10, 10))
  if (clade == 'Palaeognathae') p <- p + add_phylopic(img = ostrich, x = width * .84, y = ymax * 1.1,
                   width = width * .13, fill = '#858D89', alpha = .8)
  if (clade %in% c('Neognathae', 'Neoaves')) {
    icon <- if (clade == 'Neognathae') 'chicken' else 'falcon'
    p <- p + add_phylopic(img = icons[[icon]], x = width * .82, y = ymax * .85,
                          width = width * .14, fill = '#858D89', alpha = .7) +
      annotate('text', x = width * .82, y = ymax * 1.13,
               label = if (clade == 'Neognathae') 'Chicken' else 'Falcon',
               fontface = 'italic', size = 3, color = '#777777')
  }
  p
})
figure <- wrap_plots(plots[1:4], ncol = 2) /
  (plot_spacer() + plots[[5]] + plot_spacer() + plot_layout(widths = c(.5, 1, .5)))
ggsave(file.path(root, 'calibrations/birds/aves_likelihood_checkpoints.png'), figure,
       width = 10, height = 12.6, dpi = 300, bg = 'white')
if (!interactive()) invisible(grDevices::dev.off())
