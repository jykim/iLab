dt = read.table('rpt_monster_test_prms_mix.tsv',header=T,sep='\t')

dt = read.table('rpt_enron_test_prms_mix.tsv',header=T,sep='\t')
dt = read.table('rpt_imdb_qtest_prms_mix.tsv',header=T,sep='\t')

dt = read.table('rpt_trec_test_prms_mix.tsv',header=T,sep='\t')


dt = read.table('rpt_enron_test_prms_mix.tsv',header=T,sep='\t')
dt['Cos.pm'] = dt$Cos.p. - dt$Cos
dt['DKL.pm'] = dt$DKL.p. - dt$DKL
dt['P.1.pm'] = dt$P.1.p. - dt$P.1
dt['Cos.mp'] = dt$Cos.m. - dt$Cos.p.
dt['DKL.mp'] = dt$DKL.m. - dt$DKL.p.
dt['P.1.mp'] = dt$P.1.m. - dt$P.1.p.

cor(dt[,c(8,20:22)])
plot(dt[,c(8,20:22)])

cor(dt[,c(9,23:25)])
plot(dt[,c(9,23:25)])

t.test(dt$PRMS, dt$PRMSmx5, paired=T, alt=c('less'))
t.test(dt$MFLM, dt$PRMSmx5, paired=T, alt=c('less'))


mean(dt[,c(3:7)])
mean(dt[,c(11:19)])

cor(dt[,c(3:7)])
cor(dt[,c(11:19)])

plot(dt[,c(3:7)])
plot(dt[,c(11:19)])

par ( mfrow=c(1,2) )
plot(dt$PRMS.MFLM, dt$Cos.p - dt$Cos)
plot(dt$Mix.PRMS, dt$Cos.m - dt$Cos.p)

