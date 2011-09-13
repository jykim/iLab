$o = {:topic_id=>'dtrain', :verbose=>:mp }; $method='param_prms_rm'; $col='imdb'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_prms_rm'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :verbose=>:mp }; $method='param_rm'; $col='imdb'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>:mp }; $method='param_rm'; $col='trec'; $exp='perf'; $remark='0913'; eval IO.read('run_prms.rb')
