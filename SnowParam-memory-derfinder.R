library('BiocParallel')
library('devtools')
library('getopt')
library('derfinder')
library('GenomicRanges')

## Specify parameters
spec <- matrix(c(
	'param', 'p', 1, 'character', 'Param to use. Either snow or multicore.',
	'mcores', 'm', 1, 'integer', 'Number of cores',
	'help' , 'h', 0, 'logical', 'Display help'
), byrow=TRUE, ncol=5)
opt <- getopt(spec)

## if help was asked for print a friendly message
## and exit with a non-zero error code
if (!is.null(opt$help)) {
	cat(getopt(spec, usage=TRUE))
	q(status=1)
}

if(FALSE) {
    ## For testing
    opt <- list(mcores = 2, param = 'snow')
}

stopifnot(opt$param %in% c('snow', 'multicore'))

## Create some toy data
n <- 1e5
set.seed(20150710)
fullCov <- lapply(1:10, function(x) {
    DataFrame(
        S1 = rnorm(n, mean = 100),
        S2 = rnorm(n, mean = 100),
        S3 = rnorm(n, mean = 100),
        S4 = rnorm(n, mean = 100),
        S5 = rnorm(n, mean = 100),
        S6 = rnorm(n, mean = 100),
        S7 = rnorm(n, mean = 100),
        S8 = rnorm(n, mean = 100),
        S9 = rnorm(n, mean = 100),
        S10 = rnorm(n, mean = 100)
    )
})
names(fullCov) <- paste0('chr', seq_len(length(fullCov)))
targetSize <- 80e6
totalMapped <- colSums(do.call(rbind, lapply(fullCov, function(x) { sapply(x, sum)})))

## How large is the data?
print(object.size(fullCov), units = 'Mb')

## What about one chunk?
print(object.size(fullCov[[1]]), units = 'Mb')


## Some function to apply to the data
## Filter the data and save it by chr
myFilt <- function(chr, rawData, cutoff, totalMapped = NULL, targetSize = 80e6) {
    library('derfinder')
    message(paste(Sys.time(), 'Filtering chromosome', chr))
    
	## Filter the data
	res <- filterData(data = rawData, cutoff = cutoff, index = NULL,
        totalMapped = totalMapped, targetSize = targetSize)
	
	## Save it in a unified name format
	varname <- paste0(chr, 'CovInfo')
	assign(varname, res)
	output <- paste0(varname, '.Rdata')
	
	## Save the filtered data
	save(list = varname, file = output, compress='gzip')
	
	## Finish
	return(invisible(NULL))
}



if(opt$param == 'snow') {
    bp <- SnowParam(workers = opt$mcores, outfile = Sys.getenv('SGE_STDERR_PATH'))
} else if (opt$param == 'multicore') {
    bp <- MulticoreParam(workers = opt$mcores)
}

## Register and check that it's the correct
register(bp, default = TRUE)
bpparam()
## Still manually pass the param object
message(paste(Sys.time(), 'Filtering and saving the data with cutoff', opt$cutoff))
filteredCov <- bpmapply(myFilt, names(fullCov), fullCov, BPPARAM = bp, MoreArgs = list(cutoff = opt$cutoff, totalMapped = totalMapped, targetSize = targetSize))

## Check that it worked
load('chr1CovInfo.Rdata')
chr1CovInfo

## Session information and other info
options(width = 120)
session_info()
proc.time()
Sys.time()