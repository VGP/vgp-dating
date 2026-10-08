# Optional read-only audit after intentional calibration/config/tree updates.
# Run from any directory: Rscript /path/to/dating/treePL/calibration_config.R
# Optional manual --configs-only TOPOLOGY checks pairs and ages without trees.
# Launchers perform their config check in treepl_benchmark.py.
# Neither mode modifies files.
script <- sub('^--file=', '', grep('^--file=',commandArgs(),value=TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
args <- commandArgs(trailingOnly=TRUE)
topologies <- c('roadies_v1.1.16b','astralpro.l6p1')
configs_only <- length(args)==2 && args[1]=='--configs-only' && args[2] %in% topologies
if(length(args) && !configs_only) stop('Usage: calibration_config.R [--configs-only TOPOLOGY]')
if(configs_only) topologies <- args[2] else suppressPackageStartupMessages(library(ape))
m <- read.csv(file.path(root,'calibrations/master_calibrations.csv'),colClasses='character')
if(anyDuplicated(m$calibration_id) || anyDuplicated(m$node_name)) stop('Duplicate calibration IDs or names in master.')
issues <- 0L
report <- function(...) { issues <<- issues+1L; cat('  REVIEW:', ..., '\n') }
for(topology in topologies) {
    astral <- topology=='astralpro.l6p1'
    column <- if(astral) 'node_astralpro_l6p1' else 'node_roadies_v1_1_16b'
    if(!column %in% names(m)) stop('Missing topology column: ',column)
    if(!configs_only) tree <- read.tree(file.path(root,'trees',paste0(topology,if(astral) '.tre' else '.nwk')))
    selected <- m[!is.na(m[[column]]) & nzchar(trimws(m[[column]])),]
    cat(topology,':',nrow(selected),'calibrations recorded in master\n')
    if(!configs_only) for(i in seq_len(nrow(selected))) {
        r <- selected[i,];pair <- c(r$taxon1_accession,r$taxon2_accession)
        if(!all(pair %in% tree$tip.label)) {
            report(r$calibration_id,'defining taxon missing');next
        }
        node <- getMRCA(tree,pair)
        if(as.character(node)!=r[[column]])
            report(r$calibration_id,'master node',r[[column]],'but pair MRCA',node,
                   if(!is.na(r$notes) && nzchar(r$notes)) paste('| Existing note:',r$notes) else '')
    }
    # Each topology uses one analysis config.
    for(suffix in '.config') {
        path <- file.path(root,'dating','treePL',topology,paste0(topology,suffix))
        lines <- trimws(sub('#.*$','',readLines(path)))
        entries <- lapply(lines[grepl('^(mrca|min|max)\\s*=',lines)],function(x)
            strsplit(gsub('=', ' ',x,fixed=TRUE),'[[:space:]]+')[[1]])
        expected <- selected$node_name
        for(key in c('mrca','min','max')) {
            part <- Filter(function(x) x[1]==key,entries)
            names <- vapply(part,function(x) if(length(x)>=2) x[2] else '',character(1))
            if(anyDuplicated(names)) report(basename(path),key,'duplicate entries')
            if(!setequal(names,expected)) report(basename(path),key,
                'missing:',paste(setdiff(expected,names),collapse=','),
                'extra:',paste(setdiff(names,expected),collapse=','))
            for(i in seq_len(nrow(selected))) {
                r <- selected[i,];j<-which(names==r$node_name)
                if(length(j)!=1) next
                values <- part[[j]][-(1:2)]
                valid <- if(key=='mrca') length(values)==2 &&
                    setequal(values,c(r$taxon1_accession,r$taxon2_accession)) else
                    length(values)==1 && isTRUE(suppressWarnings(as.numeric(values))==
                        as.numeric(r[[if(key=='min') 'min_ma' else 'max_ma']]))
                if(!valid) report(basename(path),r$calibration_id,key,'differs from master')
            }
        }
        cat('  Scanned',basename(path),'\n')
    }
}
cat(issues,'item(s) for review. No files changed.\n')
if(issues) quit(status=1)
