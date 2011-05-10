dt = read.table('rpt_monster_test_prms_mix.tsv',header=T,sep='\t')

dt = read.table('rpt_trec_test_prms_mix.tsv',header=T,sep='\t')


cor(list(dt$PRMS.MFLM, dt$Cos.p - dt$Cos, dt$DKL.p - dt$DKL, dt$P.1.p - dt$P.1))
cor(dt$Mix.PRMS, dt$Cos.m - dt$Cos.p)

par ( mfrow=c(1,2) ) 
plot(dt$PRMS.MFLM, dt$Cos.p - dt$Cos)
plot(dt$Mix.PRMS, dt$Cos.m - dt$Cos.p)

mean(dt[,c(3:7)])
mean(dt[,c(11:19)])

cor(dt[,c(3:7)])
cor(dt[,c(11:19)])

plot(dt[,c(3:7)])
plot(dt[,c(11:19)])
