$o = {:redo=>true,:topic_id=>'train', :verbose=>true}; $method='param_sweep'; $col='trec'; $exp='perf'; $remark='0505_ifix'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'test', :verbose=>true}; $method='mp_oracle'; $col='trec'; $exp='perf'; $remark='0505'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true}; $method='prms_mix'; $col='enron'; $exp='perf'; $remark='0505_optmap'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true, :sparam=>get_sparam('jm',0.1) }; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0505_jm_optmap'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:opt_for=>'map',:redo=>true,:topic_id=>'train', :sparam=>get_sparam('jm',0.1)}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; $remark='0506_jm'; eval IO.read('run_prms.rb')
