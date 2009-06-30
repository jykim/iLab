log_reg_qs <- function(qs1, qs2, file_tbl)
{
	data <- read.csv(file_tbl)
	attach(data)
	tgt <- cbind(qs1, qs2)
	lgr <- glm(tgt ~ word_cnt + no_rel_docs + len_rel_docs + stdev_len_rel_docs, family= binomial("logit"))
}

log_reg_dprm <- function(file_tbl)
{
	data = read.table(file_tbl, header=T)
	attach(data)
	dprm.lambda = cbind(label, (1-label))
	dprm.lgr = glm(dprm.lambda ~ tf+ idf+ cap+ up+ top_f+ top_mp+ sub+ tex+ nam+ ema+ to+ sen, family=binomial)

	xtabs(~ tf + label)
	xtabs(~ idf + label)
	xtabs(~ top_f + label)
	xtabs(~ top_f + tf)
	xtabs(~ top_mp + tf)
	xtabs(~ tex + tf)

	summary(glm(dprm.lambda ~ tf+ idf+ cap+ up+ top_f+ top_mp+ sub+ tex+ nam+ ema+ to, family=binomial))
	summary(dprm.lgr)
	anova(dprm.lgr)
}

data = read.table('result_trec_train.txt', sep='|', col.names=c('null1','no','query','dql','prmql','prm','opt','mp','fm','top_f','top_p','mps','null2'))
attach(data)
dprm.lgr = glm(cbind(dql,prm) ~ round(mp*10) + top_f + round(top_p*10), family=binomial)
