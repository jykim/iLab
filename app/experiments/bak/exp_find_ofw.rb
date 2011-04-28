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

$xvals = $rpm_features = [:cug, :rug, :prior, :cbg , :rbg ] ; info "$xvals : #{$xvals.inspect}"
$yvals = []

o_opt = $o.dup
$xvals = $fields ; info "$xvals : #{$xvals.inspect}"
$yvals << [1.0] * $xvals.size
o_opt.merge!(:ymax=>1.0, :ymin=>0)

$mprels = $engine.get_mpset_from_flms($queries, $rlflms1)

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


 #Run retrieval at given point
 def evaluate_at(xvals , yvals , o={})
   global_param = $mu
   qid = $offset+i #Assumption : query id starts from 0
   qry_name =  "opt#{$train}#{$col_id}#{$o[:topic_id]}_q#{qid}_#{global_param}#{$mode}#{$remark}_y#{yvals.map{|l|l.round_at(3)}.join('-')}"

   qs_c[j] = $i.create_query_set("TEW_#{$query_prefix}_q#{qid}_#{e.join("-")}",
               :template=>:tew, :smoothing=>$sparam, :skip_result_set=>true, :flms=>$rlflms1, :offset=>(qid)) 
   if qs_c[j].stat.size > 0 && qs_c[j].stat['all']['map'] >= cur_max
     cur_max =  qs_c[j].stat['all']['map']

   stats['all']
 end

$mprels.each_with_index do |mprel, i|
  
  evaluate_at($xvals, $yvals)
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
  $i.create_report(binding)
end

