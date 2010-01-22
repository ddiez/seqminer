library(lattice)
foo.p <- read.delim("nuccore_pass.txt")
foo.s <- read.delim("nuccore_skip.txt")
foo.a <- read.delim("accepted.txt")

plotSizeDist(foo.p, groups = "Isolate")
plotSizeDist(foo.s)
plotSizeDist(foo.a, groups = "Source")

data.frame(L = sample(10), M = sample(100))->foo
xyplot(M ~ L, foo)

plotSizeDist <- function(x, groups) {
	x <- x[order(x[, "Length"]),]
	x <- data.frame(Index = 1:nrow(x), x)
	if (missing(groups))
		xyplot(Length ~ Index, x, scales = list(y = list(log = 10)), auto.key = list(space = "right"))
	else
		xyplot(Length ~ Index, x, aspect = "iso", scales = list(y = list(log = 10), x = list(log = 10)), auto.key = list(space = "right"), groups = eval(as.name(groups)))
}


summary(foo.p)