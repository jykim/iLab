read.pair <- function(file1, file2)
{
  r <- list();
  r[[file1]] <- read.table(file1, header=F);
  r[[file1]] <- r[[file1]][-which(r[[file1]]$V2=="all"),]
  r[[file2]] <- read.table(file2, header=F);
  r[[file2]] <- r[[file2]][-which(r[[file2]]$V2=="all"),]
  return(r);
}

# Read Input files matching RegEx Pattern
#r : list(table1, table2)
read.eval <- function(dir = ".", pattern = "^input.*")
{
  r <- list();
  files <- dir(dir, pattern);
  for (i in files)
  {
    r[[i]] <- read.table(paste(dir, "/", i, sep=""), header=F);
    r[[i]] <- r[[i]][-which(r[[i]]$V2=="all"),]
  }

  return(r);
}

ks.test.batch <- function(dir, pattern, sample_size = -1)
{
  x <- read.eval(dir, pattern)
  p <- run.ks.test(x, 'map', test=ks.test, paired=F)
  write.table(p[[2]],"ks_test.txt",sep="\t",col.names=NA)
	par( mfrow=c(4,4))
	#print(length(p))
	sample_t = boost.sample(p[[1]][[length(p[[1]])]], sample_size)
	s = lapply( p[[1]], calc.gen.prob, sample_t)
	write.table(lapply(s,sum),'fit_score.txt')
	d = lapply( p[[1]], density )
	lapply(d, plot, xlim=c(0,1))
  return(list(p[[1]],p[[2]],d,lapply(s,sum),sample_t))
}

t.test.batch <- function(dir, pattern)
{
  x <- read.eval(dir, pattern)
  p <- hyp.test(x, 'map', test=t.test, paired=T)
  write.table(p,"t_test.txt",sep="\t",col.names=NA)
  return(p)
}

do.roc.batch <- function(dir, pattern, test = 'ks', iter = 100)
{
  data = ks.test.batch(dir, pattern, sample_size=1000)
  res = c()
  no_models = length(data[[1]])
  #print("Models" + no_models)
  par( mfrow=c(3, 8))
  for(i in 1:(no_models-1))
  {
    res[[i]] = do.roc( data[[1]][[no_models]], data[[1]][[i]], test=test, iter=iter )
  }
  return( list(data, res))
}

do.roc <- function(s_true, s_model, test = 'ks', iter = 100)
{
  p_diff = c() ; p_same = c()
  r_fp = c() ; r_tp = c()
  for(i in 1:iter)
  {
    s_1 = sample(s_model, length(s_true))
    s_2 = sample(s_model, length(s_true))
    if(test == 'ks')
    {
      p_diff[i] = ks.test(s_true, s_1)$p.value
      p_same[i] = ks.test(s_2, s_1)$p.value      
    }
    else
    {
      p_diff[i] = sum(calc.gen.prob(s_true, s_1))
      p_same[i] = sum(calc.gen.prob(s_2, s_1))
    }
  }
  plot(density(p_diff), main=test)
  lines(density(p_same), lty=2)
  
  j = 1
  s_begin = min(min(p_same), min(p_diff))
  s_end   = max(max(p_same), max(p_diff))
  for(p_thr in seq(s_begin , s_end , length.out = 100))
  {
    r_tp[j] = sum(p_diff < p_thr) / iter
    r_fp[j] = sum(p_same < p_thr) / iter
    j = j + 1
  }
  plot(r_fp, r_tp)
  #plot(sort(p_diff), sort(p_same))
  #plot(p_diff, p_same)
  return(list(list(s_true,s_1,s_2),list(p_diff,p_same), sum(p_diff < p_same)))
}

# Boost given sample via density estimation
boost.sample <- function(sample, size = 1000)
{
  if(size < 0)
    return(sample)

  i = 1 ; x_begin = -1 ; x_end = -1
  d = density(sample)
  for(x in d[['x']])
  {
    if(x < 0)
      x_begin = i+1
    if(x > 1)
    {
      x_end = i-1
      break      
    }
    i = i + 1
  }
  return(sample(d[['x']][x_begin:x_end], size, TRUE, d[['y']][x_begin:x_end]))
}

# Calc. the prob. that sample is generated from dist.
# density : density estimate of some approximate distribution
# sample : sample from the true distribution
calc.gen.prob <- function(s_true, s_model)
{
	i = 1
	j = 1
	d_model = density(s_model)
	scores = rep(0, length(s_true))
	#print(length(s_true))
	for(v in sort(s_true))
	{
		while(d_model[['x']][i] <= v) #find the x point nearest to the s_true point
			i = i + 1
		scores[j] = log(d_model[['y']][i]*(d_model[['x']][i]-d_model[['x']][i-1]),2)
		j = j + 1
	}
	return(scores)
}

get.total.mass <- function(dist)
{
	i = 1
	scores =rep(0, length(dist[['x']]))
	for(y in dist[['y']])
	{ 
		if(i > 1)
			scores[i] = (dist[['x']][i]-dist[['x']][i-1]) * y
		i = i + 1
	}
	return(sum(scores))
}

#Perform ks.test among subarraries 
cross.ks.test <- function(v, fold = 2)
{
  p.val <- matrix(0, fold, fold);
  gen.prob <- matrix(0, fold, fold);
  
	a = array(v, dim=c(fold, length(v)/fold))
  for (i in 1:(fold-1))
  {
    for (j in (i+1):fold)
    {
      p.val[i,j] <- ks.test(jitter(a[i,]), jitter(a[j,]), paired=F)$p.value;
			gen.prob[i,j] <- sum( calc.gen.prob(a[i,],a[j,]) )
    }
  }

  p.val <- data.frame(p.val, row.names=seq(1,fold));
  names(p.val) <- seq(1,fold);
  return(list(p.val,gen.prob));
}

run.ks.test <- function(x, metric, ...)
{
  runs <- names(x);
  p.val <- matrix(0, length(runs), length(runs));
	input.val <- list();
  for (i in 1:(length(runs)-1))
  {
    l1 <- x[[i]][x[[i]]$V1==metric,3]; #[1:150]
		#if(data_limit != NULL)
		#  l1 = l1[1:data_limit]
		input.val[[i]] = l1
    for (j in (i+1):length(runs))
    {
      l2 <- x[[j]][x[[j]]$V1==metric,3]; #[1:150]
  		#if(data_limit != NULL)
  		#  l2 = l2[1:data_limit]
			if(j == length(runs))
				input.val[[j]] = l2
      l1 = jitter(l1)
      l2 = jitter(l2)	
      p.val[i,j] <- ks.test(t(l1), t(l2), paired=F, ...)$p.value;
			p.val[j,i] <- p.val[i,j]
    }
  }

  p.val <- data.frame(p.val, row.names=runs);
  names(p.val) <- runs;
  names(input.val) <- runs;
  return(list(input.val, p.val));
}


hyp.test <- function(x, metric, test = t.test, paired = T, ...)
{
  if (quote(test) == "binom.test")
  hyp.binom.test(x, metric, ...)

  runs <- names(x);
  p.val <- matrix(0, length(runs), length(runs));

  for (i in 1:(length(runs)-1))
  {
    l1 <- x[[i]][x[[i]]$V1==metric,3];
    for (j in (i+1):length(runs))
    {
      l2 <- x[[j]][x[[j]]$V1==metric,3];
      p.val[i,j] <- test(t(l1), t(l2), paired=paired, ...)$p.value;
			p.val[j,i] <- p.val[i,j]
    }
  }

  p.val <- data.frame(p.val, row.names=runs);
  names(p.val) <- runs;
  return(p.val);
}

hyp.binom.test <- function(x, metric, ...)
{
  runs <- names(x);
  p.val <- matrix(0, length(runs), length(runs));

  for (i in 1:(length(runs)-1))
  {
    l1 <- x[[i]][x[[i]]$V1==metric,3];
    for (j in (i+1):length(runs))
    {
      l2 <- x[[j]][x[[j]]$V1==metric,3];
      s <- (l1-l2) > 0;
      ties <- sum(l1-l2 == 0);
      p.val[i,j] <- binom.test(sum(s), length(s)-ties, ...)$p.value;
    }
  }

  p.val <- data.frame(p.val, row.names=runs);
  names(p.val) <- runs;
  return(p.val);
}

power <- function(x, metric, ...)
{
  runs <- names(x);
  pow <- matrix(0, length(runs), length(runs))

  for (i in 1:(length(runs)-1))
  {
    l1 <- x[[i]][x[[i]]$V1==metric, 3];
    for (j in (i+1):length(runs))
    {
      l2 <- x[[j]][x[[j]]$V1==metric, 3];

      if (length(l1) != length(l2))
      {
        pow[i,j] <- -1;
        next;
      }

      delta <- mean(l1 - l2);
      sd <- sd(l1 - l2);

      pow[i,j] <- power.t.test(n=length(l1), delta=delta, sd=sd, type="paired")$power;
    }
  }

  pow <- data.frame(pow, row.names=runs);
  names(pow) <- runs;
  return(pow);
}

test.test <- function(l1, l2, mean1=0, mean2=0, sd1=1, sd2=1, t=10000)
{
  l1.s <- (l1 - mean(l1))/sd(l1);
  l2.s <- (l2 - mean(l2))/sd(l2);

  t.p <- array();
  w.p <- array();
  s.p <- array();

  median <- list(med1 = array(), med2 = array());
  mean <- list(mean1 = array(), mean2 = array());
  variance <- list(var1 = array(), var2 = array());

  for (i in 1:t)
  {
    y <- rbinom(50, 1, 1/2);
    l1.p <- l1.s*y + l2.s*(1-y);
    l2.p <- l1.s*(1-y) + l2.s*y;

    l1.p <- mean1 + l1.p*sd1;
    l2.p <- mean2 + l2.p*sd2;

    median$med1 <- median(l1.p);
    median$med2 <- median(l2.p);
    mean$mean1 <- mean(l1.p);
    mean$mean2 <- mean(l2.p);
    variance$var1 <- var(l1.p);
    variance$var2 <- var(l2.p);

    t.p[i] <- t.test(l1.p, l2.p, paired=T)$p.value;
    w.p[i] <- wilcox.test(l1.p, l2.p, paired=T)$p.value;
    #s.p[i] <- binom.test(sum(l1.p-l2.p>0), length(l1.p-l2.p))$p.value;
  }

  return(list(t.p = t.p, w.p = w.p, s.p = s.p, median = median, mean = mean, variance = variance));
}

test.test.allpairs <- function(x, metric)
{
  runs <- names(x);

  p.t <- matrix(0, 40, 40);
  p.w <- matrix(0, 40, 40);

  for (i in 1:(length(runs)-1))
  {
    l1 <- x[[i]][x[[i]]$V1==metric,3];
    for (j in (i+1):length(runs))
    {
      l2 <- x[[j]][x[[j]]$V1==metric,3];
      res <- test.test(l1, l2, mean1=mean(l1), mean2=mean(l2), sd1=sd(l1), sd2=sd(l2), t=1000);
      p.t[i,j] <- sum(res$t.p <= 0.05)/1000;
      p.w[i,j] <- sum(res$w.p <= 0.05)/1000;
    }
  }

  return(list(p.t = p.t, p.w = p.w));
}


hyp.test.min <- function(x, metric, test = t.test, paired = T, ...)
{
  if (quote(test) == "binom.test")
  hyp.binom.test(x, metric, ...)

  runs <- names(x);
  p.val <- matrix(0, length(runs), length(runs));
  p <- list();
  for (i in 1:50)
  {
    p[[i]] <- matrix(0, length(runs), length(runs));
  }

  for (i in 1:(length(runs)-1))
  {
    for (j in (i+1):length(runs))
    {
      fname1 <- paste("eval/", runs[i], ".", runs[j], sep="");
      fname2 <- paste("eval/", runs[j], ".", runs[i], sep="");
      l1 <- read.table(fname1);
      l2 <- read.table(fname2);

      l1 <- l1[l1$V1==metric, 3];
      l2 <- l2[l2$V1==metric, 3];

      pos <- sum(l1-l2 > 0);
      num <- sum(l1-l2 != 0);
      #p.val[i,j] <- test(t(l1), t(l2), paired=paired, ...)$p.value;
      p.val[i,j] <- binom.test(pos, num)$p.value;

      # calc confidence
      t <- readfiles("/home/ben/incjudge/t3/runs", paste("qrels/", runs[i], ".", runs[j], sep=""), c(runs[i]), c(runs[j]), trunc=100);
      tc <- length(t$rels);
      for (k in 1:tc)
      {
        p[[k]][i,j] <- AP(t$rels[[k]], t$rankings[[1]][[k]], t$rankings[[2]][[k]], .5, maxrank=100)$p;
      }
      for (k in (tc+1):(50-tc))
      {
        p[[k]][i,j] <- 0.5;
      }
    }
  }

  p.val <- data.frame(p.val, row.names=runs);
  names(p.val) <- runs;
  return(list(p.val = p.val, conf = p));
}
