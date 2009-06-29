$len_points = $o[:len_points] || 10
$iter_count = $o[:iter_count] || 3
$tune_set   = $o[:tune_set] || false
$opt_for = $o[:opt_for] || 'map'
template_query = ($o[:prior])? :prior_query : :query

$xvals = $i.get_length_points( $len_points ) ; info "$xvals : #{$xvals.inspect}"
$yvals = []

$ptn_qry = get_ptn_query($qry_type)

def get_opt_qry_name(xvals , yvals, o)
  range = (o[:range])? o[:range] : (o[:ex_range].join('_'))
  "opt#{range}-#{$len_points}#{($o[:step])? "-step":""}-#{$qry_type}-#{$o[:prior]}_x#{xvals.join('-')}_y#{yvals.map{|l|l.round_at(3)}.join('-')}"
end

def get_opt_param(xvals , yvals)
  "method:opt,step:#{$o[:step].to_s},lengths:#{xvals.join('|')},lambdas:#{yvals.join('|')}"
end

#Run retrieval at given point
def do_retrieval_at(xvals , yvals , o)
  puts "[do_retrieval_at] #{yvals.inspect}"
  qs = $i.add_query_set($file_topic  , get_opt_qry_name(xvals , yvals, o),  
                        $ptn_qry , {:skip_result_set=>true , :prior=>$o[:prior], 
                        :smoothing=>get_opt_param(xvals , yvals) }.merge(o))
  qs.calc_stat($file_qrel)['all']
end

load 'exp/exp_optimize_method.rb'

$search_method = case $method
                 when 'golden'
                   $yvals << [0.5] * ($len_points+1)
                   GoldenSectionSearchMethod.new($xvals , $yvals , $o)
                 when 'gradient'
                   $mu = 1500
                   $yvals << $xvals.map{|d| $mu.to_f / ($mu.to_f + d) }
                   GradientSearchMethod.new($xvals , $yvals , $o)
                 when 'neighbor'
                   $mu = 1500
                   $yvals << $xvals.map{|d| $mu.to_f / ($mu.to_f + d) }
                   NeighborSectionSearchMethod.new($xvals , $yvals , $o)
                 when 's_neighbor'
                   $mu = 1500
                   $yvals << $xvals.map{|d| $mu.to_f / ($mu.to_f + d) }
                   SerialNeighborSectionSearchMethod.new($xvals , $yvals , $o)                   
                 end

$results = $search_method.search($iter_count , $o) do |xvals , yvals , type , remote|
  o = {:remote_query=>remote}
  case type
  when :tune  : o[:range] = $range_tune
  when :train : o[:ex_range] = ($o[:tune_set])? [$range_tune, $range_test] : [$range_test]
  end
  do_retrieval_at(xvals , yvals , o)[$opt_for]
end

best_results = []
0.upto($iter_count) do |i|
  break if !$yvals[i]
  result = do_retrieval_at($xvals, $yvals[i], :ex_range=> [$range_tune,$range_test] )
  best_results << [ i , result['map'] , result['P10'] , result['P30'] , get_opt_param($xvals , $yvals[i]) ]
end

if ['gradient'].include?($method)
  plot_lambda_perf =[]
  $xvals.each_with_index do |len , j|
    plot_lambda_perf << {:label=>"Length #{len}" , :data=>$results.map_with_index{|e,i|[$yvals[i][j] , e]}}
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
  length_lambda = $yvals[i].map_with_index{|e,j| [$xvals[j].to_log , e]}
  plot_length_lambda << {:label=>((i==0)? "initial value" : "#{i}th iteration") , :data=>length_lambda}
end

['1500'].each do |mu|
  length_lambda = $xvals.map{|d| [d.to_log ,mu.to_f / (mu.to_f + d) ]}
  plot_length_lambda << {:label=>"Dirichlet mu=#{mu}" , :data=>length_lambda}
end

$i.create_report(binding)
if $o[:env] == 'cval'
  $r[:map_start] , $r[:map_end] = best_results.first[1] , best_results.last[1]
  $r[:param_opt] = best_results.last[4]
end
