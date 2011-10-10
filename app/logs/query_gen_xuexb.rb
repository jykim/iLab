# Generate Stemmed Query File




# Generate Reformulations
export DH=/home2/jykim/prj/dih
java -cp /work1/croft/xuexb/codes/ProcessRelevantPassage/:/work1/croft/xuexb/codes/MyTools/:/work1/croft/xuexb/tools/lemur-dir-4.10/swig/lemur.jar\
    -Djava.library.path=/work1/croft/xuexb/tools/lemur-dir-4.10/swig ProcessRelevantPassage "" $DH/trec/ent05.known-item-topics $DH/trec/ent05.known-item-topics.refo $DH/trec/index_lists 20


# MSN N-gram

curl http://web-ngram.research.microsoft.com/rest/lookup.svc/bing-body/jun09/3/cp?u=52f34dff-0f84-4f30-9bd2-7e25f0e3dc8c&p=one+two+three&format=text
