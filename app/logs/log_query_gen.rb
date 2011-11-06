$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MKV1101', :no_cand=>2, :max_length=>5}; $method='markov'; $col='trec'; $exp='gen_query'; $remark='1101'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'train', :new_topic_id=>'MKV1103', :no_cand=>2, :max_length=>5}; $method='markov'; $col='trec'; $exp='gen_query'; $remark='1103'; eval IO.read('run_prms.rb')

22.upto(24){|i| $engine.export_term_graph("tg_#{i+1}",$term_graphs[i], $queries_a[i])}

$engine.export_term_graph("tg_#{4}",$term_graphs[3], $queries_a[3], :threshold=>0
