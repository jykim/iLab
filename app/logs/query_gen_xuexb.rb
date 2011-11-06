# Generate Stemmed Query File




# Generate Reformulations
export XUE=/work1/croft/xuexb
export DH=/home2/jykim/prj/dih
export WIKI=/lustre/work1/croft/xuexb/wiki_redirect

java -cp $XUE/codes/ProcessRelevantPassage/:$XUE/codes/MyTools/:$XUE/tools/lemur-dir-4.10/swig/lemur.jar    -Djava.library.path=$XUE/tools/lemur-dir-4.10/swig ProcessRelevantPassage "" $DH/trec/trec.topic.input $DH/trec/trec_test_sub.out

java -cp $XUE/codes/ProcessRelevantPassage/:$XUE/codes/MyTools/:$XUE/tools/lemur-dir-4.10/swig/lemur.jar    -Djava.library.path=$XUE/tools/lemur-dir-4.10/swig ProcessRelevantPassage "exp" $DH/trec/trec_test.in $DH/trec/trec_test_exp.out $DH/trec/index_lists 20 0 $XUE/stopwords/inquery_stopwords

# Using Gov2 Index

java -cp $XUE/codes/ProcessRelevantPassage/:$XUE/codes/MyTools/:$XUE/tools/lemur-dir-4.10/swig/lemur.jar    -Djava.library.path=$XUE/tools/lemur-dir-4.10/swig ProcessRelevantPassage "exp" $DH/trec/trec_test.in $DH/trec/trec_test_exp_gov2.out $XUE/indexes/gov2_4.10_nostem 20 0 $XUE/stopwords/inquery_stopwords


# Using Wikipedia Redirect Page

java -cp $XUE/codes/AnalyzeLogPattern AnalyzeLogPattern wiki_redirect $DH/trec/trec_test.in\
  $WIKI/enwiki-latest-page.sql:$WIKI/enwiki-latest-redirect.sql $DH/trec/trec_test_wiki.out false

java -cp $XUE/codes/ProcessRelevantPassage/:$XUE/codes/MyTools/:$XUE/tools/lemur-dir-4.10/swig/lemur.jar\
   -Djava.library.path=$XUE/tools/lemur-dir-4.10/swig ProcessRelevantPassage "other" $DH/trec/trec_test.in trec_test_wiki_exp.out $XUE/indexes/gov2_4.10_nostem 20 trec_test_wiki.out 0

# MSN N-gram

curl http://web-ngram.research.microsoft.com/rest/lookup.svc/bing-body/jun09/3/cp?u=52f34dff-0f84-4f30-9bd2-7e25f0e3dc8c&p=one+two+three&format=text
