$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.1}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.9}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

22.upto(24){|i| $engine.export_mem_model("tg_#{i+1}",$mem_models[i], $queries_a[i])}

i,thr = 1,0.1 ; $engine.export_mem_model("tg_#{i}",$mem_models[i-1], $queries_a[i-1], :threshold=>thr)

$engine.export_mem_model("tg_#{4}",$mem_models[3], $queries_a[3], :threshold=>0)

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.9}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')


$o = {:verbose=>true, :topic_id=>'cv1', :new_topic_id=>'MEM1111a', :no_cand=>3, :max_length=>5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1111a'; eval IO.read('run_prms.rb')

$o = {:verbose=>false, :topic_id=>'cv1', :new_topic_id=>'MEM1111', :no_cand=>3, :max_length=>5, :skip_gen=>true, :skip_feature=>true}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1111'; eval IO.read('run_prms.rb')

$o = {:verbose=>false, :topic_id=>'cv1', :new_topic_id=>'MEM1111b', :no_cand=>5, :max_length=>5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1111b'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'cv1', :new_topic_id=>'MEM1114', :no_cand=>5, :skip_feature=>false}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1114'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'cv31', :new_topic_id=>'MEM1115', :no_cand=>9, :smooth_ratio=>0.5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1115'; eval IO.read('run_prms.rb')

$o = {:export=>true, :topic_id=>'cv31', :new_topic_id=>'MEM1121', :no_cand=>5, :smooth_ratio=>0.5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1121'; eval IO.read('run_prms.rb')

$o = {:export=>true, :topic_id=>'cv31', :new_topic_id=>'MEM1121', :no_cand=>5, :smooth_ratio=>0.5, :skip_gen=>true, :skip_feature=>true}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1121'; eval IO.read('run_prms.rb')

$o = {:export=>true, :verbose=>true, :topic_id=>'cv31', :new_topic_id=>'MEM1121', :no_cand=>9, :smooth_ratio=>0.5, :skip_gen=>true, :skip_feature=>true}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1121'; eval IO.read('run_prms.rb')

$o = {:export=>true, :verbose=>true, :topic_id=>'cv31', :new_topic_id=>'MEM1127', :no_cand=>9, :smooth_ratio=>0.5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1127'; eval IO.read('run_prms.rb')
