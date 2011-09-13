$o = {:topic_id=>'dtrain', :verbose=>:mp }; $method='param_prms_rm'; $col='imdb'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_prms_rm'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :verbose=>:mp }; $method='param_rm'; $col='imdb'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_rm'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_bm25f'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='golden'; $mode='bm25_bf' ; $col='trec'; $exp='optimize_prm'; $remark='0913'; eval IO.read('run_prms.rb')
