foo <- read.table("stat_result.txt")

goo <- foo[grep("-core|-est", foo[,2]),]
goo[,2] <- gsub("-core|-est", "", goo[,2])
ooo <- c()
for(o in unique(as.character(goo[,1]))) {
	sel <- goo[,1] == o
	too <- goo[sel,]
	for(s in unique(too[,2])) {
		tmp <- too[too[,2] == s,, drop = FALSE]
		ss <- sum(tmp[,4])
		ooo <- rbind(ooo,c(unique(as.character(tmp[,1])), s , unique(as.character(tmp[,3])), ss))
	}
}

res <- data.frame(Ortholog = ooo[,1], Taxon = ooo[,2], Type = ooo[,3], Count = as.numeric(ooo[,4]))

tmp <- foo[foo[,3] == "spp", ]
colnames(tmp) <- c("Ortholog", "Taxon", "Type", "Count")

res <- rbind(res, tmp)


library(lattice)


xyplot(Count ~ Ortholog | Taxon, res, group = Type, auto.key = list(space = "right", cex = 0.6), scale = list(y = list(log = 10), x = list(rot = 90, cex = 0.7)))