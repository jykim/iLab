### Find the best mixture weights for PRM-S
# 
load 'app/experiments/exp_optimize_method.rb'

$iter_count = $o[:iter_count] || 3
#$tune_set   = $o[:tune_set] || false
$opt_for = $o[:opt_for] || 'map'
#$remote = $o[:remote] || false
$mode = $o[:mode] || :smoothing
$template_query = $o[:template] || :prm
$ptn_qry = $ptn_qry_title

$xvals = (0...($mp_types.size)).to_a.shuffle;#$mp_types #= [:cug, :rug, :cbg, :prior, :rbg ]
info "$xvals : #{$xvals.inspect}" ; $o[:xvals] = $xvals
$yvals = []

o_opt = $o.dup
case $mode
when :mix_weights
  $yvals << [0.5] * $xvals.size
  o_opt.merge!(:ymax=>1.0, :ymin=>0.01)
end
#p $yvals

$qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam) if !$qs
$rsflms = get_rsflms($qs) if !$rsflms
$mprel = $engine.get_mpset_from_flms($queries, $rlflms1)

def get_opt_qry_name(xvals , yvals, o)
  global_param = $mu
                "opt#{$train}#{$col_id}#{$o[:topic_id]}_#{global_param}#{$mode}#{$remark}_y#{yvals.map{|l|l.round_at(3)}.join('-')}"
end

#Run retrieval at given point
def evaluate_at(xvals , yvals , o={})
  $mpmix   = $engine.get_mixture_mpset($queries, $mp_types ,yvals)
  #$mpmix_h = $mpmix.map{|e|$engine.marr2hash e}
  #klds   = $engine.mpset_calc( $mprel, $mpmix_h ){|mp1,mp2|mp1.kld_s(mp2.to_p)}
  #cosims = $engine.mpset_calc( $mprel, $mpmix_h ){|mp1,mp2|mp1.cosim(mp2.to_p)}
  case $opt_for
  when 'kld'
    {'kld'=>(-klds.avg)}
  when 'cosine'
    {'cosine'=>cosims.avg}
  when 'map'
    qs = $i.create_query_set(get_opt_qry_name( $mp_types, yvals, o), o.merge(:template=>:tew, :mps=>$mpmix, :skip_result_set=>true, :smoothing=>( $o[:sparam] || $sparam_prm) ))
    stats = qs.calc_stat($file_qrel)
  #  info ["KLD/COS/MAP", yvals, -klds.avg, cosims.avg, stats['all']['map']].flatten.inspect if $o[:verbose]
    stats['all']
  end
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
  evaluate_at(xvals , yvals.map{|e|(e.to_s.scan(/e/).size>0)? 0.0 : e} , $o.merge(:remote_query=>remote))[$opt_for]
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
    result = evaluate_at($xvals, $yvals[i] )#, :ex_range=> [$range_tune,$range_test]
    best_results << [ i , result[$opt_for] ,  $yvals[i].map{|e|e.to_f.r3}.inspect ]
  end
=begin
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
=end
  $i.create_report(binding)
  #if $o[:env] == 'cval'
  #  $r[:map_start] , $r[:map_end] = best_results.first[1] , best_results.last[1]
  #  $r[:param_opt] = best_results.last[4]
  #end
end

