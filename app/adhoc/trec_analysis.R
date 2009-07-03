
#dprm.lgr = glm(cbind(DQL,PRM) ~ MP + FreqField, family= binomial("logit"))
setwd('/Users/lifidea/Documents/Project/dih/R-Analysis')
source("sig_test.R")

r = do.roc.batch('data',"trec_.*(manual|1218)_PRM\.eval", test = 'ks', iter = 100)

# ############### ROC Analysis
res = ks.test.batch('data',"trec_.*(manual|1218)_PRM\.eval",sample_size=1000)
par( mfrow=c(2,2)) ; iter = 500
r_gen = do.roc( res[[1]]$trec_man, res[[1]]$trec_D_RN,test='gen', iter=iter)
r_ks  = do.roc( res[[1]]$trec_man, res[[1]]$trec_D_RN,test='ks', iter=iter)

plot(density(r_gen[[2]][[1]]))
plot(density(r_gen[[2]][[2]]), lty=2)
plot(density(r_ks[[2]][[1]]))
plot(density(r_ks[[2]][[2]]), lty=2)

sort(r_gen[[2]][[1]])
sort(r_gen[[2]][[2]])
sort(r_ks[[2]][[1]])                             
sort(r_ks[[2]][[2]])
#####################################  SIGIR Submission
#CORRELATION OF MP and Perf.
data = read.table('trec_test.txt', sep=',', header = TRUE)
attach(data)
par ( mfrow=c(1,2) ) 
data2 = data[-which(PRMDQL == 0),]
plot(data2$MP, data2$PRMDQL,main="Correlation of MP and Performance", xlim=range(0,1.0),xlab='Accuracy of MP Estimate', ylab='RecipRank (PRM-S - DQL)')
#lines(supsmu(data2$PRMDQL, data2$MP))
cor(data2$MP, data2$PRMDQL)
lines(lowess(data2$MP, data2$PRMDQL))

mp1 = data[which(PRMDQL > 0.1),]$MP
mp2 = data[which(PRMDQL < -0.1),]$MP
t.test(mp1,mp2, paired=FALSE)$p.value
plot(density(mp1),main="Comparison of Density", ylim=range(0,2.2), xlim=range(0,1), xlab='Accuracy of MP Estimate')
lines(density(mp2), lty=2)

#CORRELATION OF GENPROB and Perf.

data = read.table('trec_gen.txt', sep='\t', header = TRUE)
#data2 = data[-which(PRM_S - DQL == 0),]
attach(data)
par ( mfrow=c(2,2) ) 
plot(F_RN_RN - D_RN    , PRM_S - DQL)
plot(F_RN_TF - D_TF    , PRM_S - DQL)
plot(F_RN_IDF - D_IDF  , PRM_S - DQL)
plot(F_RN_TIDF - D_TIDF, PRM_S - DQL)
cor(PRM_S - DQL, F_RN_RN - D_RN)
cor(PRM_S - DQL, F_RN_TF - D_TF)
cor(PRM_S - DQL, F_RN_IDF - D_IDF)
cor(PRM_S - DQL, F_RN_TIDF - D_TIDF)

#---------------------------------------- R Contour Plot
sort.data.frame <- function(x, by){
    # Author: Kevin Wright
    # with some ideas from Andy Liaw
    # http://tolstoy.newcastle.edu.au/R/help/04/07/1076.html
 
    # x: A data.frame
    # by: A one-sided formula using + for ascending and - for descending
    #     Sorting is left to right in the formula
  
    # Useage is:
    # library(nlme);
    # data(Oats)
    # sort(Oats, by= ~nitro-Variety)
 
    if(by[[1]] != "~")
        stop("Argument 'by' must be a one-sided formula.")
 
    # Make the formula into character and remove spaces
    formc <- as.character(by[2]) 
    formc <- gsub(" ", "", formc) 
    # If the first character is not + or -, add +
    if(!is.element(substring(formc, 1, 1), c("+", "-")))
        formc <- paste("+", formc, sep = "")
 
    # Extract the variables from the formula
    vars <- unlist(strsplit(formc, "[\\+\\-]"))    
    vars <- vars[vars != ""] # Remove any extra "" terms
 
    # Build a list of arguments to pass to "order" function
    calllist <- list()
    pos <- 1 # Position of + or -
    for(i in 1:length(vars)){
        varsign <- substring(formc, pos, pos)
        pos <- pos + 1 + nchar(vars[i])
        if(is.factor(x[, vars[i]])){
            if(varsign == "-") {
                calllist[[i]] <- -rank(x[, vars[i]])
            } else {
                calllist[[i]] <- rank(x[, vars[i]])
            }
        } else {
            if(varsign == "-") {
                calllist[[i]] <- -x[, vars[i]]
            } else {
                calllist[[i]] <- x[,vars[i]]
            }
        }
    }
    return(x[do.call("order", calllist), ])
}

contour_grid <- function(title, filename)
{
  t = read.table(filename)
  x = sort(unique(t[,1]))
  y = sort(unique(t[,2]))
  z = t(array(sort.data.frame(t,by= ~ +V1+V2+V3)$V3,c(11,11)))
  contour(x, y, z, method='flattest',nlevels=15,main=title,xlab="weight(subject)",ylab="weight(text)")
  #persp(x, y, z, theta=30,phi=30,ticktype='detailed') 
}

par(mfrow= c(2,2))
contour_grid("BM25" , "grid_trec@optimize_prm@grid@0505@mode,:bm25_weight-verbose,true-topic_id,train-reset_param,true.out")
contour_grid("BM25F", "grid_trec@optimize_prm@grid@0505@mode,:bm25f_weight-redo,true-verbose,true-topic_id,train-reset_param,true.out")
contour_grid("MFLM" , "grid_trec@optimize_prm@grid@0506@mode,:hlm_weight-redo,true-verbose,true-topic_id,train-reset_param,true.out")
contour_grid("MFLMF", "grid_trec@optimize_prm@grid@0508_dir@mode,:prmf_weight-verbose,true-topic_id,train-limit_fields,2-reset_param,true.out")

par(mfrow= c(2,2))
contour_grid("BM25" , "grid_trec@optimize_prm@grid@0505@mode,:bm25_weight-verbose,true-topic_id,test-reset_param,true.out")
contour_grid("BM25F", "grid_trec@optimize_prm@grid@0505@mode,:bm25f_weight-redo,true-verbose,true-topic_id,test-reset_param,true.out")
contour_grid("MFLM" , "grid_trec@optimize_prm@grid@0506@mode,:hlm_weight-redo,true-verbose,true-topic_id,test-reset_param,true.out")
contour_grid("MFLMF", "grid_trec@optimize_prm@grid@0508_dir@mode,:prmf_weight-verbose,true-topic_id,test-limit_fields,2-reset_param,true.out")
