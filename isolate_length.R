library(lattice)

foo.pass = read.delim("nuccore_pass.txt")

plotSizeDist("nuccore_size.txt")
plotSizeDist("nuccore_pass.txt")
plotSizeDist("nuccore_skip.txt")
plotSizeDist("nuccore_isolate.txt")
plotSizeDist("nuccore_strain.txt")
plotSizeDist("nuccore_country.txt")
plotSizeDist("nuccore_clone.txt")
plotSizeDist("nuccore_notype.txt")

plotSizeDist <- function(file) {
	tmp <- read.delim(file)
	tmp <- tmp[order(tmp[,2]),]
	tmp <- data.frame(Index = 1:nrow(tmp), tmp)
	xyplot(Length ~ Index, tmp, scales = list(y = list(log = 10)))
}