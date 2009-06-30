
setwd('/Users/lifidea/Documents/Project/dih/R-Analysis')
source('sig_test.R')

p = do.ks.test('.',"0161.*lists.*(1001|manual).*PRM.eval")
p = do.ks.test('.',"0161.*lists.*(1001|manual).*DQL.eval")

p = do.ks.test('.',"0141.*lists.*(1001|manual).*PRM.eval")
p = do.ks.test('.',"0141.*lists.*(1001|manual).*DQL.eval")

p = do.ks.test('.',"imdb.*(1008|train)_PRM.eval")
p = do.ks.test('.',"imdb.*(1008|train)_DQL.eval")

p = do.ks.test('.',"0161.*lists.*(1004p|manual).*DQL.eval")
p = do.ks.test('.',"0161.*lists.*(1004p|manual).*PRM.eval")

p = do.ks.test('.',"0141.*lists.*(1004p|manual).*DQL.eval")
p = do.ks.test('.',"0141.*lists.*(1004p|manual).*PRM.eval")

p = do.ks.test('.',"0141.*lists.*(1005_|manual).*PRM.eval")

p = do.ks.test('.',"0161.*lists.*(TIDF|MIX|manual).*DQL.eval")
p = do.ks.test('.',"0161.*lists.*(TIDF|MIX|manual).*PRM.eval")

p = do.ks.test('.',"0141.*lists.*(1006np|manual).*DQL.eval")
p = do.ks.test('.',"0141.*lists.*(1006np|manual).*PRM.eval")

setwd('/Users/lifidea/Documents/Project/dih/R-Analysis')

########### CIKM Submission
d = read.table('pd_gen.txt',header=T)
par ( mfrow=c(1,2) ) 
plot(d[['MP_Accuracy']],d[['PRMS.DQL']],main="Correlation of MP and Performance",xlab='Accuracy of MP Estimate', ylab='Performance (PRM-S - DQL)')
lines(lowess(d[['MP_Accuracy']],d[['PRMS.DQL']], f=1))
plot(d[['MP_Accuracy']],-d$PRMD.PRMS,main="Correlation of MP and Performance",xlab='Accuracy of MP Estimate', ylab='Performance (PRM-S - PRM-D)')
lines(lowess(d[['MP_Accuracy']],-d$PRMD.PRMS, f=1))
