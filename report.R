foo <- read.table("log", header = TRUE)

library(lattice)
barchart(count ~ ortholog | taxon, foo, scales = list(rot = 45))

sel.p <- grepl("^p", foo[, "taxon"])
barchart(count ~ ortholog | taxon, foo[sel.p,], scales = list(rot = 45))

sel.o <- grepl("var|rifin|cir|vir", foo[, "ortholog"])
barchart(count ~ ortholog | taxon, foo[sel.o,], scales = list(rot = 45, y = list(log = 2)))

barchart(count ~ ortholog | taxon, foo[sel.o & sel.p,], scales = list(rot = 45, y = list(log = 2)))



foo2 <- read.table("log2", header = TRUE)
foo2.b <- foo2[foo2[, "best_eval"] <= 0.001, ]
foo2.b <- foo2[foo2[, "best_eval"] <= 0.01, ]

barchart(foo[, c("taxon", "ortholog")], auto.key = list(space = "right"), par.settings = simpleTheme(col = col))

barchart(foo2.b[, c("taxon", "ortholog")], auto.key = list(space = "right"), par.settings = simpleTheme(col = col))

barchart(foo2[, c("fragment", "complete", "coherent")], auto.key = list(space = "right"))

sel <- foo2.b[, "ortholog"] == "rifin_stevor"
barchart(foo2.b[sel, "taxon"], par.settings = simpleTheme(col = col))
