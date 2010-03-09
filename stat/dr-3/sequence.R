seq1 <- read.table("stat_sequence.txt")
colnames(seq1) <- c("Sequence", "DNA", "CDS", "Translation")

seq2 <- read.table("stat_family.txt")
colnames(seq2) <- c("Sequence", "DNA", "CDS", "Translation")

library(lattice)
histogram(~ DNA + CDS + Translation, data = seq1, scales = list(relation = "free", x = list(log = 10)), xlab = "Sequence Length", type = "count", auto.key = list(space = "right", cex = 0.6), main = "Distribution of Length in DR-3", col = "darkgreen", border = "whitesmoke", par.settings = list(strip.background = list(col = "lightgreen")))

histogram(~ DNA + CDS + Translation, data = seq2, scales = list(relation = "free", x = list(log = 10)), xlab = "Sequence Length", type = "count", auto.key = list(space = "right", cex = 0.6), main = "Distribution of Length in DR-3*", col = "darkgreen", border = "whitesmoke", par.settings = list(strip.background = list(col = "lightgreen")))

seq1.ord <- seq1[order(seq1[,"DNA"], decreasing = TRUE),]
seq2.ord <- seq2[order(seq2[,"DNA"], decreasing = TRUE),]