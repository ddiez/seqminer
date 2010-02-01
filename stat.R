res <- read.delim("stat_result.txt")
src <- read.delim("stat_source.txt")
library(lattice)


heatMap <- function(mat) {
	foo <- matrix(NA, nrow = nlevels(mat[, "Ortholog"]), ncol = nlevels(mat[, "Taxon"]), dimnames = list(levels(mat[, "Ortholog"]), levels(mat[, "Taxon"])))
	apply(mat, 1, function(x) foo[x[1], x[2]] <<- as.numeric(x[4]))
	col <- colorRampPalette(c("grey90", "steelblue", "darkblue", "orange"))(100)
	levelplot(foo, col.regions = col, scales = list(rot = 45), colorkey = list(tick.number = 10, at = seq(-1000, signif(max(mat[, "Count"]), 2), 1000)), cuts = 9, xlab = "Orthologs", ylab = "Species", main = "Distribution of sequences in varDB DR-3")
	foo
}
heatMap(res)


barchart((nuccore_pass + nuccore_skip) +nuccore_pass + (nucest_pass + nucest_skip) + nucest_pass + (nuccore_pass + nucest_pass) + accepted ~ Taxon, src, scales = list(x = list(rot = 45)), auto.key = list(space = "right", cex = 0.7), ylab = "Number of Sequences")