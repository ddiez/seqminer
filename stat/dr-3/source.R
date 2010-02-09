res <- read.delim("stat_source.txt")
library(lattice)


barchart((nuccore_pass + nuccore_skip) +nuccore_pass + (nucest_pass + nucest_skip) + nucest_pass + (nuccore_pass + nucest_pass) + accepted ~ Taxon, res, scales = list(x = list(rot = 45), y = list(log = 10)), auto.key = list(space = "right", cex = 0.7), ylab = "Number of Sequences")