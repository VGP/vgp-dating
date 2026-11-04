# Bird likelihood checkpoints. Run from any directory.
suppressPackageStartupMessages({library(ape); library(ggplot2); library(patchwork); library(rphylopic)})
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
data <- read.csv(file.path(root, 'calibrations/checkpoint_estimates.csv'))
pairs <- list(Aves = c('GCF_040807025.1', 'GCF_016700215.2'),
              Palaeognathae = c('GCF_040807025.1', 'GCA_047922985.1'))
files <- c(ROADIES = 'roadies_v1.1.16b/roadies_v1.1.16b.independent.fast95.tre',
           ASTRAL = 'astralpro.l6p1/astralpro.l6p1.independent.fast95.tre')
trees <- lapply(file.path(root, 'dating/mdcat', files), function(path) {
  tree <- read.nexus(path); tree$tip.label <- gsub("'", '', tree$tip.label, fixed = TRUE)
  stopifnot(is.rooted(tree), is.ultrametric(tree)); tree
})
names(trees) <- names(files)
if (!interactive()) grDevices::pdf(NULL)
ostrich <- get_phylopic(uuid = 'df5979fc-7cdd-41c7-ac47-7107ba3f7e1a')
plots <- lapply(names(pairs), function(clade) {
  values <- data[data$clade == clade & is.finite(data$age_ma), ]
  stopifnot(nrow(values) > 1)
  ages <- do.call(rbind, lapply(names(trees), function(method) {
    t <- trees[[method]]; stopifnot(all(pairs[[clade]] %in% t$tip.label))
    depth <- node.depth.edgelength(t)
    data.frame(method = method, age = mean(depth[seq_len(Ntip(t))]) - depth[getMRCA(t, pairs[[clade]])])
  }))
  width <- if (clade == 'Aves') 260 else 130
  iqr <- IQR(values$age_ma); qs <- quantile(values$age_ma, c(.25, .75))
  values$outlier <- values$age_ma < qs[1] - 1.5 * iqr | values$age_ma > qs[2] + 1.5 * iqr
  d <- density(values$age_ma[!values$outlier], from = 0, to = width, n = 512)
  curve <- data.frame(age = d$x, density = d$y); ymax <- max(d$y)
  p <- ggplot(curve, aes(age, density)) +
    geom_area(fill = '#A2B3A8', alpha = .38) +
    geom_line(color = '#81968A', linewidth = .65) +
    geom_rug(data = subset(values, !outlier), aes(x = age_ma), inherit.aes = FALSE,
             color = '#555555', linewidth = .5, alpha = .7, length = unit(.025, 'npc')) +
    geom_rug(data = subset(values, outlier), aes(x = age_ma), inherit.aes = FALSE,
             color = '#B76A61', linewidth = .6, length = unit(.025, 'npc')) +
    geom_segment(data = ages, aes(x = age, xend = age, y = 0, yend = 1.15 * ymax,
                                  color = method, linetype = method), inherit.aes = FALSE, linewidth = .8) +
    scale_color_manual(values = c(ROADIES = '#246B83', ASTRAL = '#B7653D')) +
    scale_linetype_manual(values = c(ROADIES = 'solid', ASTRAL = 'longdash')) +
    coord_cartesian(xlim = c(0, width), ylim = c(0, 1.55 * ymax), expand = FALSE) +
    annotate('text', x = width * .04, y = ymax * 1.45, label = clade, hjust = 0, size = 5, color = '#333333') +
    annotate('text', x = width * .04, y = ymax * 1.30,
             label = paste(sprintf('%s %.1f Ma', ages$method, ages$age), collapse = '   ·   '),
             hjust = 0, size = 3, color = '#666666') +
    labs(x = 'Age (Ma)', y = NULL, color = NULL, linetype = NULL) +
    theme_classic(base_size = 11) +
    theme(axis.line.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank(),
          axis.line = element_line(color = '#777777', linewidth = .4),
          legend.position = 'none', plot.margin = margin(12, 14, 10, 10))
  p + add_phylopic(img = ostrich, x = width * .84, y = ymax * 1.1,
                   width = width * .13, fill = '#858D89', alpha = .8)
})
figure <- wrap_plots(plots, ncol = 2)
ggsave(file.path(root, 'calibrations/birds/aves_likelihood_checkpoints.png'), figure,
       width = 11, height = 4.2, dpi = 300, bg = 'white')
if (!interactive()) invisible(grDevices::dev.off())
