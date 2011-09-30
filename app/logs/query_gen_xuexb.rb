export DH=/home2/jykim/prj/dih
java -cp /work1/croft/xuexb/codes/ProcessRelevantPassage/:/work1/croft/xuexb/codes/MyTools/:/work1/croft/xuexb/tools/lemur-dir-4.10/swig/lemur.jar\
    -Djava.library.path=/work1/croft/xuexb/tools/lemur-dir-4.10/swig ProcessRelevantPassage "" $DH/trec/ent05.known-item-topics $DH/trec/ent05.known-item-topics.refo $DH/trec/index_lists 20
