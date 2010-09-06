dr3 = read.table("dr-3/stat_final.txt", as.is = TRUE)
dr4 = read.table("dr-4/stat_final.txt", as.is = TRUE)

f = data.frame(Family = dr4[,1], Organism = dr4[,2], Percentage = 100*(dr4[,3]-dr3[,3])/dr3[,3], stringsAsFactors = FALSE)

sel = f[,3] != 0

f2 = f[sel,]

write.table(f2[order(f2[,3], decreasing = TRUE),], file = "sum-dr4.txt", quote = FALSE, sep = "\t", row.names = FALSE)

library(lattice)
barchart(Percentage ~ Organism | Family, f2, groups = Organism, auto.key = list(space = "right", cex = 0.8, rect.fill = "red"), scale = list(x = list(rot = 45)))
