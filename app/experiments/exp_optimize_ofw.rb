### Find the best mixture weights for PRM-S
# 
load 'app/experiments/exp_optimize_method.rb'

$iter_count = $o[:iter_count] || 3
$i.add_relevant_set($file_qrel)
$h_rl = $i.rl.docs.map_hash{|d| [[d.did,d.qid].join , d.relevance]}
$best_results = []
$o.merge!(:ymax=>1.0, :ymin=>0.01)

def get_opt_qry_name(qidx, xvals , yvals, o)
  global_param = $mu
 "opt#{$col_id}#{$o[:topic_id]}_q#{qidx}_#{global_param}#{$remark}_y#{yvals.map{|l|l.round_at(3)}.join('-')}"
end

#Run retrieval at given point
def evaluate_at(qidx, xvals , yvals , o={})
  qs = $i.crt_add_query_set(get_opt_qry_name(qidx, xvals , yvals, o), o.merge(:template=>:tew, :smoothing=>( $o[:sparam] || $sparam_prm) ))
  qs.rs.docs.each{ |d| d.fetch_relevance($h_rl) }
  qs.rs.avg_prec
end


def replace_probs(mps, probs)
  mps.each_with_index do |mp,i|
    mp[1].each_with_index do |e,j|
      e[1] = probs[i+j]
    end
  end
  [mps]
end

# Extract probability pairs from MPs
def get_probs(mps)
  result = []
  mps.each_with_index do |mp,i|
    mp[1].each_with_index do |e,j|
      result << [[mp[0], e[0]].join("."), e[1]]
    end
  end
  result
end

def find_opt_for(qidx)
  $mprel = $engine.get_map_prob($queries[qidx], :flm=>$rlflms1[qidx])
  p get_probs($mprel)
  $xvals = get_probs($mprel).map{|e|e[0]}
  $yvals = [get_probs($mprel).map{|e|e[1]}]
  $search_method = case $method
                   when 'grid'
                     GridSearchMethod.new($xvals , $yvals , $o)
                   when 'golden'
                     # $yvals << [0.5] * ($len_points+1)
                     GoldenSectionSearchMethod.new($xvals , $yvals , $o)
                   when 'gradient'
                     GradientSearchMethod.new($xvals , $yvals , $o)
                   when 'neighbor'
                     NeighborSectionSearchMethod.new($xvals , $yvals , $o)
                   when 's_neighbor'
                     SerialNeighborSectionSearchMethod.new($xvals , $yvals , $o)                   
                   end
                   
  $results = $search_method.search($iter_count , $o) do |xvals , yvals , type , remote|
    evaluate_at(qidx, xvals , yvals , $o.merge(:offset=>(qidx+$offset), :mps=>replace_probs($mprel, yvals)))
  end
  result_opt = evaluate_at(qidx, $xvals, $yvals[-1], :offset=>(qidx+$offset), :mps=>replace_probs($mprel, $yvals[-1]) )
  result_ofw = evaluate_at(qidx, $xvals, $yvals[-1], :offset=>(qidx+$offset), :mps=>[$mprel] )
  [ qidx , result_opt , result_ofw, get_probs(replace_probs($mprel, $yvals[-1])).inspect ]
end

0.upto($queries.size - 1) do |i|
  $best_results << find_opt_for(i)
end

$i.create_report(binding)