dt = read.table('query-click-sessions.tsv.stat.only',sep='\t',header=T);

hist(dt[dt$length <= 20,]$length, breaks=seq(1,20,by=1), xlim=c(0,20))

dt_op = dt[dt$quote>0 | dt$bAND>0 |	dt$bOR>0 |	dt$bNOT>0 |	dt$plus>0 | dt$minus>0 |	dt$field>0 |	dt$range>0 |	dt$fuzzy >0, ]

dt_fq = table( dt_op$field, cut(dt_op$quote, c(0,1,3,5,7,9),include.lowest = T))
