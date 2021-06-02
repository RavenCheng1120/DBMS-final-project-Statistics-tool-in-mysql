p = seq(0,1,length.out=1001)
Wtable <- matrix(c(1:100100), 100, 1001)


for(i in c(0:99)){
  Wtable[i,] = qsignrank(p, i+4)
}
colnames(Wtable) <- p
rownames(Wtable) <- c(4:103)
write.csv(Wtable,"wilcoxonTable.csv")
