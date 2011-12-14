
# Term RM Parameter Tuning

$o = {:topic_id=>'dtrain' }; $method='param_rm'; $col='imdb'; $exp='perf'; $remark='0914_refined'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train' }; $method='param_rm'; $col='trec'; $exp='perf'; $remark='0914_refined'; eval IO.read('run_prms.rb')

# Term RM Parameter Tuning (indri implementation)

$o = {:topic_id=>'train' }; $method='param_rm_indri'; $col='monster'; $exp='perf'; $remark='0915'; eval IO.read('run_prms.rb')


# Field RM Parameter Tuning

$o = {:topic_id=>'dtrain', :verbose=>:mp }; $method='param_prms_rm'; $col='imdb'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_prms_rm'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

# Regression-based MP weight training

$o = {:topic_id=>'train', :verbose=>:mp}; $method='train_mpmix' ; $col='trec'; $exp='perf'; $remark='0915'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp}; $method='final' ; $col='trec'; $exp='perf'; $remark='0915_reg_mpmix'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp}; $method='train_mpmix' ; $col='monster'; $exp='perf'; $remark='0915'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp}; $method='final' ; $col='monster'; $exp='perf'; $remark='0915_reg_mpmix'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :verbose=>:mp}; $method='train_mpmix' ; $col='imdb'; $exp='perf'; $remark='0915'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtest', :verbose=>:mp}; $method='final' ; $col='imdb'; $exp='perf'; $remark='0915_reg_mpmix'; eval IO.read('run_prms.rb')


# BM25F Parameter Tuning
#$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_bm25f'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp, :mode=>:bm25_bf }; $method='golden' ; $col='trec'; $exp='optimize_prm'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :mode=>:bm25f_weight }; $method='golden' ; $col='trec'; $exp='optimize_prm'; $remark='0914'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :mode=>:bm25_bf }; $method='golden' ; $col='imdb'; $exp='optimize_prm'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :mode=>:bm25_bf }; $method='golden';  $col='monster'; $exp='optimize_prm'; $remark='0913'; eval IO.read('run_prms.rb')

# Baseline Including BM25F & RM

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true}; $method='final' ; $col='trec'; $exp='perf'; $remark='0919'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtest', :verbose=>:mp, :redo=>true}; $method='final' ; $col='imdb'; $exp='perf'; $remark='0919'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true}; $method='final' ; $col='monster'; $exp='perf'; $remark='0919'; eval IO.read('run_prms.rb')

tt = read.table('MP_trec_train.out')
tr = lm(tt$V8 ~ tt$V3 + tt$V4 + tt$V5 + tt$V6 + tt$V7 )
tr

it = read.table('MP_imdb_dtrain.out')
ir = lm(it$V8 ~ it$V3 + it$V4 + it$V5 + it$V6 + it$V7 )
ir

mt = read.table('MP_monster_train.out')
mr = lm(mt$V8 ~ mt$V3 + mt$V4 + mt$V5 + mt$V6 + mt$V7 )
mr

# Analyzing Performance per Query

$o = {:topic_id=>'train', :verbose=>:mp, :range=>(1..25).to_a}; $method='final'; $col='trec'; $exp='document'; $remark='0920'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp}; $method='final'; $col='trec'; $exp='perf'; $remark='0920'; eval IO.read('run_prms.rb')

# Random Restart in Mixture Weight Training

$o = {:topic_id=>'train', :verbose=>:mp, :mode=>:mix_weights, :opt_for=>'map' }; $method='golden' ; $col='trec'; $exp='optimize_mix'; $remark='0926'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :verbose=>:mp, :mode=>:mix_weights, :opt_for=>'map' }; $method='golden' ; $col='imdb'; $exp='optimize_mix'; $remark='0926'; eval IO.read('run_prms.rb')

# BM25F Retraining

$o = {:topic_id=>'train', :mode=>:bm25_bf }; $method='golden';  $col='monster'; $exp='optimize_prm'; $remark='0925'; eval IO.read('run_prms.rb')

# Query Generation

$o = {:verbose=>true, :topic_id=>'dtest', :new_topic_id=>'MKV1003', :no_cand=>3, :max_length=>4}; $method=nil; $col='imdb'; $exp='gen_query'; $remark='1003'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test', :new_topic_id=>'MKV1003', :no_cand=>3, :max_length=>4}; $method=nil; $col='monster'; $exp='gen_query'; $remark='1003'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test', :new_topic_id=>'MKV1012', :no_cand=>5, :max_length=>5}; $method=nil; $col='trec'; $exp='gen_query'; $remark='1012'; eval IO.read('run_prms.rb')

# Rexa 

$o = {:topic_id=>'all', :verbose=>true}; $method='baseline'; $col='rexa'; $exp='perf'; $remark='1005'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'all', :verbose=>:mp, :range=>(1..5).to_a, :topk=>5}; $method='baseline'; $col='rexa'; $exp='document'; $remark='1011'; eval IO.read('run_prms.rb')


# Improving Term Weighting

$o = {:topic_id=>'train', :verbose=>:mp, :range=>(1..25).to_a, :topk=>5}; $method='baseline'; $col='trec'; $exp='document'; $remark='1009'; eval IO.read('run_prms.rb')

$engine.debug_prm_query(9, ['lists-027-16405062', 'lists-080-9157092'], :prms, :op_comb=>:wsum)
