p = seq(0,1,length.out=1001)
Wtable <- matrix(c(1:100100), 100, 1001)


for(i in c(0:99)){
  Wtable[i,] = qf(1-p, df1 = i+4, df2 = 2)
}
colnames(Wtable) <- p
rownames(Wtable) <- c(4:103)
write.csv(Wtable,"RepeatANOVA.csv")
