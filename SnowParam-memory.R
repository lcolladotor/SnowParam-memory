library('BiocParallel')
library('devtools')
library('getopt')

## Specify parameters
spec <- matrix(c(
	'param', 'p', 1, 'character', 'Param to use. Either snow, multicore, or serial.',
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

stopifnot(opt$param %in% c('snow', 'multicore', 'serial'))

## Create some toy data
n <- 2000
set.seed(20150709)
mat <- data.frame(matrix(rnorm(n^2 * opt$mcores), ncol = n, nrow = n * opt$mcores))

## Stored in data.frame so split() would work nicely
mat.list <- split(mat, rep(seq_len(opt$mcores), each = n))
rm(mat)

## How large is the data?
print(object.size(mat.list), units = 'Mb')

## What about one chunk?
print(object.size(mat.list[[1]]), units = 'Mb')

## Some function to appy to the data
projection <- function(x) { x <- as.matrix(x); res = diag(1, nrow = nrow(x), ncol = ncol(x)) - x %*% solve(t(x) %*% x) %*% t(x); gc()}

if(R.Version()$minor %in% c('1.1', '1.2')) {
    if(opt$param == 'snow') {
        bp <- SnowParam(workers = opt$mcores,
            outfile = Sys.getenv('SGE_STDERR_PATH'))
    } else if (opt$param == 'multicore') {
        bp <- MulticoreParam(workers = opt$mcores)
    } else if (opt$param == 'serial') {
        bp <- SerialParam()
    }
} else {
    if(opt$param == 'snow') {
        bp <- SnowParam(workers = opt$mcores,
            outfile = Sys.getenv('SGE_STDERR_PATH'), log = TRUE)
    
    } else if (opt$param == 'multicore') {
        bp <- MulticoreParam(workers = opt$mcores, log = TRUE)
    } else if (opt$param == 'serial') {
        bp <- SerialParam(log = TRUE)
    }
}


## Register and check that it's the correct
register(bp, default = TRUE)
bpparam()
## Still manually pass the param object
result <- bplapply(mat.list, projection, BPPARAM = bp)
result


## Session information and other info
options(width = 120)
session_info()
proc.time()
Sys.time()
