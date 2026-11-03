# Audit the treePL calibrations, or synchronize them from the master with --update.
# Run from any directory: Rscript /path/to/dating/treePL/calibration_config.R [--update]
script <- sub('^--file=', '', grep('^--file=',commandArgs(),value=TRUE)[1])
root <- dirname(dirname(dirname(normalizePath(script))))
args <- commandArgs(trailingOnly=TRUE)
topologies <- c('roadies_v1.1.16b','astralpro.l6p1')
configs_only <- length(args)==2 && args[1]=='--configs-only' && args[2] %in% topologies
update <- length(args)==1 && args[1]=='--update'
if(length(args) && !configs_only && !update) stop('Usage: calibration_config.R [--update | --configs-only TOPOLOGY]')
if(configs_only) topologies <- args[2] else suppressPackageStartupMessages(library(ape))
m <- read.csv(file.path(root,'calibrations/master_calibrations.csv'),colClasses='character')
if(anyDuplicated(m$calibration_id) || anyDuplicated(m$node_name)) stop('Duplicate calibration IDs or names in master.')
# Build and validate both updated configs before writing either one.
if(update) {
    required <- c('calibration_id','node_name','node_roadies_v1_1_16b','node_astralpro_l6p1',
                  'min_ma','max_ma','taxon1_accession','taxon2_accession')
    if(!all(required %in% names(m))) stop('Master calibration list is missing required columns.')
    if(anyNA(m$calibration_id) || anyNA(m$node_name) || any(!nzchar(trimws(m$calibration_id))) ||
       any(!grepl('^[A-Za-z0-9_.-]+$',m$node_name))) stop('Invalid calibration ID or node name.')
    lo <- suppressWarnings(as.numeric(m$min_ma)); hi <- suppressWarnings(as.numeric(m$max_ma))
    if(any(!is.finite(lo) | !is.finite(hi) | lo < 0 | lo > hi)) stop('Invalid calibration bounds in master.')
    plans <- list()
    for(topology in topologies) {
        astral <- topology=='astralpro.l6p1'
        column <- if(astral) 'node_astralpro_l6p1' else 'node_roadies_v1_1_16b'
        tree <- read.tree(file.path(root,'trees',paste0(topology,if(astral) '.tre' else '.nwk')))
        selected <- m[!is.na(m[[column]]) & nzchar(trimws(m[[column]])),,drop=FALSE]
        for(i in seq_len(nrow(selected))) {
            r <- selected[i,]; pair <- c(r$taxon1_accession,r$taxon2_accession)
            if(anyNA(pair) || any(!nzchar(trimws(pair))) || anyDuplicated(pair) || !all(pair %in% tree$tip.label))
                stop(topology, ': invalid or missing defining taxa for ',r$calibration_id)
            node <- getMRCA(tree,pair)
            if(is.null(node) || as.character(node)!=r[[column]])
                stop(topology, ': node mapping differs from tree for ',r$calibration_id)
        }
        path <- file.path(root,'dating','treePL',topology,paste0(topology,'.config'))
        original <- readLines(path,warn=FALSE)
        result <- character(); seen <- character()
        for(line in original) {
            clean <- trimws(sub('#.*$','',line))
            if(!grepl('^(mrca|min|max)\\s*=',clean)) { result <- c(result,line); next }
            parts <- strsplit(gsub('=',' ',clean,fixed=TRUE),'[[:space:]]+')[[1]]
            if(length(parts)<3) stop('Malformed calibration in ',path,': ',line)
            key <- parts[1]; name <- parts[2]; id <- paste(key,name,sep=':')
            if(id %in% seen) stop('Duplicate calibration in ',path,': ',id)
            seen <- c(seen,id)
            index <- match(name,selected$node_name)
            if(is.na(index)) next
            r <- selected[index,]; old <- parts[-(1:2)]
            value <- if(key=='mrca') c(r$taxon1_accession,r$taxon2_accession) else r[[if(key=='min') 'min_ma' else 'max_ma']]
            same <- if(key=='mrca') length(old)==2 && setequal(old,value) else
                length(old)==1 && isTRUE(suppressWarnings(as.numeric(old))==as.numeric(value))
            if(same) result <- c(result,line) else {
                comment <- if(grepl('#',line,fixed=TRUE)) paste0(' #',sub('^[^#]*#','',line)) else ''
                result <- c(result,paste0(key,' = ',name,' ',paste(value,collapse=' '),comment))
            }
        }
        for(i in seq_len(nrow(selected))) {
            r <- selected[i,]; name <- r$node_name
            missing <- c('mrca','min','max')[!paste(c('mrca','min','max'),name,sep=':') %in% seen]
            if(length(missing)) {
                result <- c(result,'')
                for(key in missing) {
                    value <- if(key=='mrca') c(r$taxon1_accession,r$taxon2_accession) else r[[if(key=='min') 'min_ma' else 'max_ma']]
                    result <- c(result,paste(key,'=',name,paste(value,collapse=' ')))
                }
            }
        }
        plans[[topology]] <- list(path=path,original=original,result=result)
    }
    for(plan in plans) {
        if(!identical(plan$original,plan$result)) {
            tmp <- tempfile(pattern='.calibrations-',tmpdir=dirname(plan$path))
            writeLines(plan$result,tmp,useBytes=TRUE)
            if(!file.rename(tmp,plan$path)) stop('Could not update config: ',plan$path)
            cat('Updated',plan$path,'from master calibration list.\n')
        } else cat('Calibration settings already current:',plan$path,'\n')
    }
}
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
    path <- file.path(root,'dating','treePL',topology,paste0(topology,'.config'))
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
cat(issues,'item(s) for review.',if(update) '' else 'No files changed.', '\n')
if(issues) quit(status=1)
