# Facebook & Twitter Collections

$o = {:verbose=>true, :topic_id=>'fb2'}; $method='param_smt'; $col='facebook'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'fb3'}; $method='param_smt'; $col='facebook'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'fb4'}; $method='param_smt'; $col='facebook'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'tw1'}; $method='param_smt'; $col='twitter'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'tw5'}; $method='param_smt'; $col='twitter'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'tw6'}; $method='param_smt'; $col='twitter'; $exp='perf'; $remark='1202_CJ'; eval IO.read('run_prms.rb')

# INEX-IMDB Collection

$o = {:verbose=>true, :topic_id=>'test'}; $method='param_smt'; $col='imdbx'; $exp='perf'; $remark='1212'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test'}; $method='param_smt'; $col='imdbx'; $exp='perf'; $remark='1212'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test'}; $method='baseline'; $col='imdbx'; $exp='document'; $remark='1212'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :mode=>:mix_weights, :opt_for=>'map' }; $method='golden' ; $col='imdbx'; $exp='optimize_mix'; $remark='1213'; eval IO.read('run_prms.rb')

# TREC DQL vs. PRM-S Debugging

$o = {:topic_id=>'test', :verbose=>:mp, :range=>[125,138,36,83,29,31,122,27,62,70], :topk=>5}; $method='baseline'; $col='trec'; $exp='document'; $remark='1213'; eval IO.read('run_prms.rb')

# Field-specific Smoothing Experiments

['sent','name','email','subject','to','text'].each do |field|
  $o = {:verbose=>true, :topic_id=>'train', :hlm_weight=>[1.0], :fields=>[field]}; $method='param_smt'; $col='trec'; $exp='perf'; $remark="1212_smt_#{field}"; eval IO.read('run_prms.rb')
end
