
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

########### Rank List Merging
setwd('/Users/lifidea/Documents/Project/dih/pd')
d = read.table('c0141_manual.csv',header=T,sep=',')

# Cor of cs_score & performance
cs_score.perf <- function(cs1, cs2, retmodel = 'DQL',norm = 'none', merge_type = 'cori')
{
  x = d[[paste('s',cs2,sep='')]]-d[[paste('s',cs1,sep='')]]
  y = d[[paste(retmodel,norm,cs2,merge_type,sep='_')]]-d[[paste(retmodel,norm,cs1,merge_type,sep='_')]]
  plot(x, y,xlab='rcol_score',ylab='perf',main=sprintf("%s-%s (cor:%.3f)",cs1,cs2,round(cor(x, y),digits=3)))
  list(list(x,y))
}

cs_score.perf.all <-function(retmodel = 'DQL',norm = 'minmax', merge_type = 'cori')
{
  par( mfrow=c(2,3))
  cs_score.perf('uniform','cql',retmodel,norm,merge_type)
  cs_score.perf('uniform','mpmean',retmodel,norm,merge_type)
  cs_score.perf('uniform','mpmax',retmodel,norm,merge_type)
  cs_score.perf('cql','mpmax',retmodel,norm,merge_type)
  cs_score.perf('cql','mpmean',retmodel,norm,merge_type)
  cs_score.perf('mpmax','mpmean',retmodel,norm,merge_type)  
}

# Higher correlation when raw scores are normalized
cs_score.perf.all('DQL','minmax','cori')
cs_score.perf.all('DQL','none','cori')

# 
cor(d[['dql']], d[['DQL_none_cql_cori']])
cor(d[['dql']], d[['DQL_minmax_cql_cori']])
cor(d[['prm']], d[['PRM.S_none_cql_cori']])
cor(d[['prm']], d[['PRM.S_minmax_cql_cori']])


cor(d[['prm']], d[['scql']])
cor(d[['prm']], d[['smpmax']])
cor(d[['prm']], d[['smpmean']])
cor(d[['dql']], d[['scql']])
cor(d[['dql']], d[['smpmax']])
cor(d[['dql']], d[['smpmean']])

> cor(d[['avg_prm']], d[['scql']])
[1] 0.1001214
> cor(d[['avg_prm']], d[['smpmax']])
[1] 0.5460515
> cor(d[['avg_prm']], d[['smpmean']])
[1] 0.5288502
> cor(d[['avg_dql']], d[['scql']])
[1] 0.06064586
> cor(d[['avg_dql']], d[['smpmax']])
[1] 0.2518359
> cor(d[['avg_dql']], d[['smpmean']])
[1] 0.2211264

> cor(d[['avg_dql']], d[['avg_prm']])
[1] 0.5837235
> cor(d[['scql']], d[['smpmean']])
[1] 0.3111641
> cor(d[['scql']], d[['smpmax']])
[1] 0.3061847
> cor(d[['smpmean']], d[['smpmax']])
[1] 0.9730839


mean(d[which(d$smpmax>0.2),]$DQL_minmax_mpmax_cori)
mean(d[which(d$smpmax>0.2),]$DQL_minmax_mpmax_multiply)
mean(d[which(d$smpmax<0.2),]$DQL_minmax_mpmax_multiply)
mean(d[which(d$smpmax<0.2),]$DQL_minmax_mpmax_cori)

> mean(d[which(d$smpmax>0.2),]$DQL_minmax_mpmax_cori)
[1] 0.3967812
> mean(d[which(d$smpmax>0.2),]$DQL_minmax_mpmax_multiply)
[1] 0.41075
> mean(d[which(d$smpmax<0.2),]$DQL_minmax_mpmax_multiply)
[1] 0.007611111
> mean(d[which(d$smpmax<0.2),]$DQL_minmax_mpmax_cori)
[1] 0.06233333
>

> aggregate(d,list(d$scql>-1),mean)[seq(36,45)]
  rdoc rcql rmpmax rmpmean   scql  smpmax smpmean suniform     dql     prm
1   NA 0.52    0.6    0.64 0.4597 0.48312  0.5075      0.2 0.45776 0.58172