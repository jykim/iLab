
def get_opt_qry_name(xvals , yvals, o)
  global_param = case $mode
               when :bm25f_bf || :bm25f_weight : $k1
               else $mu
               end
               "opt#{$train}#{$col_id}#{$o[:topic_id]}_#{global_param}#{$mode}#{$remark}_x#{xvals.map{|e|e[0,1]}.join('')}_y#{yvals.map{|l|l.round_at(3)}.join('-')}"
end

#Run retrieval at given point
def do_retrieval_at(xvals , yvals , o={})
  puts "[do_retrieval_at::#{$mode}] #{yvals.inspect}"
  case $mode
  when :mp_weights
    #o.merge!(:mp_weights=>())
  when :smoothing
    o.merge!(:smoothing=>IndriInterface.get_field_sparam($fields , yvals, $mu),
             :hlm_weights=>([0.1]*$fields.size))
  when :smoothing_jm
    o.merge!(:smoothing=>IndriInterface.get_field_sparam($fields , yvals, $lambda, 'jm'),
             :hlm_weights=>([0.1]*$fields.size))
  when :hlm_weights
    $template_query = :hlm #(($mus)? IndriInterface.get_field_sparam($fields , $mus, $mu) : ['method:jm,lambda:0.1'])
    o.merge!(:smoothing=>$sparam_prm, :hlm_weights=>yvals)
  when :bm25f_bf
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam($fields , yvals, $k1),  :hlm_weights=>([0.1]*$fields.size), :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25f_weight
    $template_query = :hlm
    #info "[do_retrieval_at::#{$mode}] Using bfs = #{bfs.inspect}"
    o.merge!(:smoothing=>IndriInterface.get_field_bparam($fields , ($bfs || [0.5] * $fields.size)),  :hlm_weights=>yvals, :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25_bf
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam2($fields , yvals, $k1), :hlm_weights=>([0.1]*$fields.size), :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25_weight
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam2($fields , ($bs || [0.5] * $fields.size)),  :hlm_weights=>yvals, :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :prior
    prior_weight = $fields.map_hash_with_index{|e,i|[e,yvals[i]]}# ; p prior_weight
    o.merge!(:smoothing=>$sparam, :prior_weight=>prior_weight)
  end
  qs = $i.create_query_set( get_opt_qry_name($fields , yvals, o), o.merge(:template=>$template_query, :skip_result_set=>true, :lambda=>0.9))
  qs.calc_stat($file_qrel)['all']
end