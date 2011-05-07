# Parameter Sweep

$o = {:redo=>true,:topic_id=>'train', :verbose=>true}; $method='param_sweep'; $col='trec'; $exp='perf'; $remark='0505_ifix'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'train', :verbose=>true}; $method='param_sweep'; $col='monster'; $exp='perf'; $remark='0507'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'dtrain', :verbose=>true}; $method='param_sweep'; $col='imdb'; $exp='perf'; $remark='0507'; eval IO.read('run_prms.rb')

# Weight Training

$o={:mode=>:hlm_weights,:topic_id=>'train'}; $col='enron' ;$exp='optimize_prm'; $method='golden'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:opt_for=>'map',:topic_id=>'test', :sparam=>get_sparam('jm',0.1)}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; $remark='0506'; eval IO.read('run_prms.rb')

# Evaluate Oracle

$o = {:redo=>true,:topic_id=>'test', :sparam=>get_sparam('jm',0.1), :verbose=>true}; $method='mp_oracle'; $col='trec'; $exp='perf'; $remark='0507_jm'; eval IO.read('run_prms.rb')

# Get Results

# TREC

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true, :sparam=>get_sparam('jm',0.1) }; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0505_jm_optmap'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:opt_for=>'map',:redo=>true, :topic_id=>'train', :sparam=>get_sparam('jm',0.1)}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; $remark='0506_jm'; eval IO.read('run_prms.rb')

# Enron

$o={:mode=>:mix_weights,:opt_for=>'map',:redo=>true, :topic_id=>'train', :sparam=>get_sparam('jm',0.1)}; $col='enron' ;$exp='optimize_rpm'; $method='golden'; $remark='0506_jm'; eval IO.read('run_prms.rb')


$o = {:topic_id=>'test', :verbose=>:mp, :sparam=>get_sparam('jm',0.1), :redo=>true}; $method='prms_mix'; $col='enron'; $exp='perf'; $remark='0506_jm_optmap'; eval IO.read('run_prms.rb')

# IMDB

$o = {:topic_id=>'dtrain', :verbose=>:mp, :redo=>true}; $method='prms_mix'; $col='imdb'; $exp='perf'; $remark='0507'; eval IO.read('run_prms.rb')

