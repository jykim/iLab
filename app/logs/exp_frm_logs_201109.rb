
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

# Baseline Including BM25F

$o = {:topic_id=>'test', :verbose=>:mp}; $method='final' ; $col='trec'; $exp='perf'; $remark='0915'; eval IO.read('run_prms.rb')
