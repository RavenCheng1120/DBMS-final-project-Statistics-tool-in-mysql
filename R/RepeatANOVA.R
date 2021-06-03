p = seq(0.001,1,length.out=1000)
Wtable <- matrix(c(1:100000), 100, 1000)


for(i in c(0:100)){
  Wtable[i,] = qf(1-p, df1 = i+4, df2 = 2)
}
colnames(Wtable) <- p
rownames(Wtable) <- c(4:103)
write.csv(t(Wtable),"RepeatANOVA.csv")
