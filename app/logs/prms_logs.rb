$o = {:redo=>true,:topic_id=>'train', :verbose=>true}; $method='param_sweep'; $col='enron'; $exp='perf'; $remark='0505'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'test', :verbose=>true}; $method='mp_oracle'; $col='trec'; $exp='perf'; $remark='0505'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true}; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0505'; eval IO.read('run_prms.rb')
