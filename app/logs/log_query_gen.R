
par( mfrow=c(2,4))
plot(density(d[d$qtype=='G' & d$ftype=='POS',]$uni))
lines(density(d[d$qtype=='M' & d$ftype=='POS',]$uni), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='POS',]$bi))
lines(density(d[d$qtype=='M' & d$ftype=='POS',]$bi), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='POS',]$uni1))
lines(density(d[d$qtype=='M' & d$ftype=='POS',]$uni1), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='POS',]$bi1))
lines(density(d[d$qtype=='M' & d$ftype=='POS',]$bi1), lty=2)

plot(density(d[d$qtype=='G' & d$ftype=='MSN',]$uni))
lines(density(d[d$qtype=='M' & d$ftype=='MSN',]$uni), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='MSN',]$bi))
lines(density(d[d$qtype=='M' & d$ftype=='MSN',]$bi), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='MSN',]$uni1))
lines(density(d[d$qtype=='M' & d$ftype=='MSN',]$uni1), lty=2)
plot(density(d[d$qtype=='G' & d$ftype=='MSN',]$bi1))
lines(density(d[d$qtype=='M' & d$ftype=='MSN',]$bi1), lty=2)


dt = read.table('features_0102.tsv',header=T)
cor(dt)
