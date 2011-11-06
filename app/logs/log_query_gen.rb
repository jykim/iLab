$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.1}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.5}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MEM1103refo', :no_cand=>5, :max_length=>5, :smooth_ratio=>0.9}; $method='memory'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

22.upto(24){|i| $engine.export_term_graph("tg_#{i+1}",$term_graphs[i], $queries_a[i])}

$engine.export_term_graph("tg_#{4}",$term_graphs[3], $queries_a[3], :threshold=>0)

