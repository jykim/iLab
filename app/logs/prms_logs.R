> d = read.table('result_0405.txt',sep='\t',header=T)
> plot(d$D_KL, d$PRMSrl - d$PRMS)
> d2 = d[which(d$PRMSrl - d$PRMS > 0),]

> plot(d2$D_KL, d2$PRMSrl - d2$PRMS)

> cor(d2$D_KL, d2$PRMSrl - d2$PRMS)
[1] 0.06885386

> t.test(d$PRMS, d$PRMSmix, paired= T)

t = -0.987, df = 124, p-value = 0.3256

> t.test(d$PRMS, d$PRMSmix, paired= T,alternative=c('less'))

t = -0.987, df = 124, p-value = 0.1628

