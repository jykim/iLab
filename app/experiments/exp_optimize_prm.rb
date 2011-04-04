#HLM Weight Optimization
#$o={:ymax=>2.0,:mode=>:weight}; $col='monster' ;$exp='optimize_prm'; $method='s_neighbor'; eval IO.read('run.rb')
#BM25f B_f optimization
#$o={:k1=>1.0,:mode=>:bm25f, :topic_id=>train}; $col='trec' ;$exp='optimize_prm'; $method='s_neighbor'; eval IO.read('run.rb')
$iter_count = $o[:iter_count] || 3
$tune_set   = $o[:tune_set] || false
$opt_for = $o[:opt_for] || 'map'
$remote = $o[:remote] || false
$mode = $o[:mode] || :smoothing
$template_query = $o[:template] || :prm
$ptn_qry = $ptn_qry_title
if $o[:limit_fields]
  $fields = $fields[0..($o[:limit_fields]-1)]
  if $o[:reset_param]
    $bs = [0.5] * $fields.size
    $bfs = [0.5] * $fields.size
    $mus = nil
  end
end
$xvals = $fields ; info "$xvals : #{$xvals.inspect}"
$yvals = []

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
  when :smoothing
    o.merge!(:smoothing=>IndriInterface.get_field_sparam(xvals , yvals, $mu),
             :hlm_weights=>([0.1]*$fields.size))
  when :smoothing_jm
    o.merge!(:smoothing=>IndriInterface.get_field_sparam(xvals , yvals, $lambda, 'jm'),
             :hlm_weights=>([0.1]*$fields.size))
  when :hlm_weights
    $template_query = :hlm
    o.merge!(:smoothing=>(($mus)? IndriInterface.get_field_sparam(xvals , $mus, $mu) : ['method:jm,lambda:0.1']), :hlm_weights=>yvals)
  #when :smoothing2   : o.merge!(:smoothing=>IndriInterface.get_field_sparam2(xvals , yvals)) #Train collection mu as well
  when :prmf_weight
    $template_query = :hlm
    o.merge!(:smoothing=>['method:raw','node:wsum,method:dirichlet,mu:50'], :hlm_weights=>yvals, :indri_path=>$indri_path_dih)
  #when :smoothing2   : o.merge!(:smoothing=>IndriInterface.get_field_sparam2(xvals , yvals)) #Train collection mu as well
  when :bm25f_bf
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam(xvals , yvals, $k1), 
             :hlm_weights=>([0.1]*$fields.size), :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25f_weight
    $template_query = :hlm
    #info "[do_retrieval_at::#{$mode}] Using bfs = #{bfs.inspect}"
    o.merge!(:smoothing=>IndriInterface.get_field_bparam($fields , ($bfs || [0.5] * $fields.size)), 
             :hlm_weights=>yvals, :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25_bf
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam2(xvals , yvals, $k1), 
             :hlm_weights=>([0.1]*$fields.size), :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :bm25_weight
    $template_query = :hlm
    o.merge!(:smoothing=>IndriInterface.get_field_bparam2($fields , ($bs || [0.5] * $fields.size)), 
             :hlm_weights=>yvals, :param_query=>"-msg_path='#{$bm25f_path}'", :indri_path=>$indri_path_dih)
  when :prior
    prior_weight = $fields.map_hash_with_index{|e,i|[e,yvals[i]]}# ; p prior_weight
    o.merge!(:smoothing=>$sparam, :prior_weight=>prior_weight)
  end
  qs = $i.create_query_set( get_opt_qry_name(xvals , yvals, o), 
                            o.merge(:template=>$template_query, :skip_result_set=>true, :lambda=>0.9))
  qs.calc_stat($file_qrel)['all']
end

load 'exp/exp_optimize_method.rb'
o_opt = $o.dup
case $mode
when :prior
  $yvals << [1.0] * $xvals.size
when :smoothing
  $yvals << [10] * $xvals.size
  o_opt.merge!(:ymax=>$mu, :cvg_range=>1)
#when :smoothing2
#  $yvals << [$mu].concat([10] * $xvals.size)
#  o_opt.merge!(:ymax=>$mu*2, :cvg_range=>1)
when :bm25f_bf
  $yvals << [0.5] * $xvals.size
  o_opt.merge!(:ymax=>1.0, :cvg_range=>0.02)
when :bm25f_weight
  $yvals << [0.5] * $fields.size
  o_opt.merge!(:ymax=>1.0)
when :bm25_bf
  $yvals << [0.5] * $xvals.size
  o_opt.merge!(:ymax=>1.0, :cvg_range=>0.02)
when :bm25_weight
  $yvals << [0.5] * $fields.size
  o_opt.merge!(:ymax=>1.0)
when :smoothing_jm
  $yvals << [0.5] * $xvals.size
  o_opt.merge!(:ymax=>1, :cvg_range=>0.02)
when :prmf_weight
  $yvals << [0.5] * $fields.size
  o_opt.merge!(:ymax=>1.0)
when :hlm_weights
  $yvals << [0.5] * $fields.size
  o_opt.merge!(:ymax=>1.0)
end

$search_method = case $method
                 when 'grid'
                   GridSearchMethod.new($xvals , $yvals , o_opt)
                 when 'golden'
                   # $yvals << [0.5] * ($len_points+1)
                   GoldenSectionSearchMethod.new($xvals , $yvals , o_opt)
                 when 'gradient'
                   GradientSearchMethod.new($xvals , $yvals , o_opt)
                 when 'neighbor'
                   NeighborSectionSearchMethod.new($xvals , $yvals , o_opt)
                 when 's_neighbor'
                   SerialNeighborSectionSearchMethod.new($xvals , $yvals , o_opt)                   
                 end

$results = $search_method.search($iter_count , $o) do |xvals , yvals , type , remote|
  #case type
  #when :tune  : o[:range] = $range_tune
  #when :train : o[:ex_range] = ($o[:tune_set])? [$range_tune, $range_test] : [$range_test]
  #end
  do_retrieval_at(xvals , yvals.map{|e|(e.to_s.scan(/e/).size>0)? 0.0 : e} , $o.merge(:remote_query=>remote))[$opt_for]
end

if $method == 'grid'
  $output = []
  $results.each do |k,v|
    v.each do |k2,v2|
      $output << [k,k2,v2]
    end
  end
  $i.dsvwrite('grid_'+get_expid_from_env()+'.out', $output)
  #$i.create_report(binding)
else
  best_results = []
  0.upto($iter_count) do |i|
    break if !$yvals[i]
    result = do_retrieval_at($xvals, $yvals[i] )#, :ex_range=> [$range_tune,$range_test]
    best_results << [ i , result['map'] , result['P10'] , result['P30'] ,  $yvals[i].map{|e|e.to_f.r3}.inspect ]
  end

  if ['gradient'].include?($method)
    plot_lambda_perf =[]
    $xvals.each_with_index do |len , j|
      plot_lambda_perf << {:label=>"Field #{len}" , :data=>$results.map_with_index{|e,i|[$yvals[i][j] , e]}}
    end
  else
    #plots = {len1=>[{1st iter} , {2nd iter}] , len2=>[{1st iter} , {2nd iter}]}
    plot_lambda_perf = {}
    $xvals.each_with_index do |len , j|
      plot_lambda_perf[len] = [{:label=>"Initial Value" , :data=>{$yvals[0][j]=>best_results[0][1] }}]
      1.upto($iter_count) do |i|
        plot_lambda_perf[len] << {:label=>"#{i}th iteration" , :data=>$results[i][j]}
      end
    end
  end

  plot_length_lambda = []
  0.upto($iter_count) do |i|
    break if !$yvals[i]
    length_lambda = $yvals[i].map_with_index{|e,j| [$xvals[j] , e]}
    plot_length_lambda << {:label=>((i==0)? "initial value" : "#{i}th iteration") , :data=>length_lambda}
  end

  $i.create_report(binding)
  #if $o[:env] == 'cval'
  #  $r[:map_start] , $r[:map_end] = best_results.first[1] , best_results.last[1]
  #  $r[:param_opt] = best_results.last[4]
  #end
end

