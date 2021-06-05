p = seq(0.001,1,length.out=1000)
Wtable <- matrix(c(1:1000), 1, 1000)

Wtable[1,] = qchisq(1-p, df = 2)

colnames(Wtable) <- p
write.csv(t(Wtable),"Chi2.csv")
