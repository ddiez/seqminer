foo1 <- read.table("stat_source_original.txt")
foo1 <- cbind(foo1, rep("original", nrow(foo1)))
colnames(foo1) <- c("Taxon", "Type", "Original", "Status")

foo2 <- read.table("stat_source_accepted.txt")
foo2 <- cbind(foo2, rep("accepted", nrow(foo2)))
colnames(foo2) <- c("Taxon", "Type", "Accepted", "Status")

res <- data.frame(foo1[, 1:3], foo2[, 3, drop = F], Ratio = foo2[,3]/foo1[,3])
res[is.nan(res[, "Ratio"]), "Ratio"] <- 0
xyplot(Original + Accepted + Ratio ~ Taxon, res, group = Type, scales = list(relation = "free", y = list(log = 10), x = list(rot = 45)), auto.key = list(space = "right"))

