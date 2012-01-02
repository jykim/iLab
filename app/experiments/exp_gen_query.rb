load 'app/experiments/exp_optimize_method.rb'


$features = ["Length", "Position", "IDF", "MSNgram", "MSNgram2", "PosTagF", "PosTagL", "PosTag", "PosTag2"]
$prob_restart = 0.2# $engine.estimate_prob_restart($queries_train_a, $rlflms_train)
$doc_no = $engine.get_col_stat()[:doc_no]
$idfh = $engine.get_df().map_hash{|k,v|[k, Math.log($doc_no.to_f / v)]}

# Process Test Queries
$queries_a = $queries.map{|q|q.split(/\s+/).map{|e|$engine.kstem(e)}}
$rlflms = $engine.get_rel_flms($file_qrel, 2, :freq=>true) if !$rlflms
$rlfvs = $engine.get_rel_fvs($file_qrel) if !$rlfvs
File.open(to_path("#{$file_topic}.in"), "w"){|f|f.puts $queries.map{|e|e+" ."}.join("\n")}
$pos_queries = run_postagger(to_path("#{$file_topic}.in"))

# Estimate Statistics of Training Queries
$queries_train_a = $queries_train.map{|q|q.split(/\s+/).map{|e|$engine.kstem(e)}}
$rlflms_train = $engine.get_rel_flms($file_qrel_train, 2) if !$rlflms_train
$pos_queries_train = run_postagger(to_path("#{$file_topic_train}.in"))

$ldist ||= $queries_train_a.map{|e|e.size}.to_dist.to_p
$field_set_train ||= $engine.get_mpset_from_flms($queries_train, $rlflms_train.map{|e|e[1]}).
  map{|e|$engine.mhash2arr e}.map{|mps|mps.map{|e|e[1][0][0]}}
File.open(to_path("#{$file_topic_train}.in"), "w"){|f|f.puts $queries.map{|e|e+" ."}.join("\n")}
$pos_queries_train = run_postagger(to_path("#{$file_topic_train}.in"))
$gen_pos = $pos_queries_train.map{|e|e.split(/\s+/).map{|e|e.split("_")[1]}[0..-2]}.flatten.to_pdist
$trans_pos = train_trans_probs($pos_queries_train)

unless $o[:skip_gen]
  case $method
  when 'memory'
    $mem_models = $engine.gen_mem_model $rlflms, :fweights=>$field_set_train.flatten.to_dist.to_p
    $query_set = $mem_models.map_with_index do |tg,i|
      #$engine.export_mem_model("tg_#{i}",tg, 'dot')
      $engine.gen_memory_query(tg, $o.merge(:qno=>i, :smooth_lm=>$queries_a[i].to_dist.to_p))
    end
  when 'markov'
    puts "Initializing parameters..."
    $engine.train_mixture_weights($queries, $rlflms)
    $engine.train_trans_probs($queries, $rlflms1) if !$trans
    puts "Generate candidates..."
    $query_set = $engine.get_markov_queries($queries, $rlflms, $o) #if !$cand_set
  end
end

puts "Canculating query features..."

unless $o[:skip_feature]
  File.open(to_path("cand_#{$file_topic}.in"), "w"){|f|
    f.puts $query_set.map{|e|e.map{|e2|e2.join(" ")+" ."}}.collapse.join("\n")}
  $pos_cands = run_postagger(to_path("cand_#{$file_topic}.in"), :force=>true)
  $cand_set = $engine.calc_feature_set($queries_a, $query_set, $rlfvs, $o)
end

#unless $o[:skip_train]

puts "Training feature weights..."

case $o[:topic_id]
when 'all'
  $qrange_train, $qrange_test = 0..75, 76..150
else
  $qrange_train, $qrange_test = 0..49, 50..99
end

$comb_weights_grid = $engine.train_weights_by_cascent($cand_set[$qrange_train])
$comb_weights_svm = $engine.train_weights_by_ranksvm($cand_set[$qrange_train], $o)

$perf_test_grid = $engine.evaluate_cand_set($cand_set[$qrange_test], $comb_weights_grid[-1][0])
$perf_test_svm = $engine.evaluate_cand_set($cand_set[$qrange_test], $comb_weights_svm)

puts "Weights trained : #{$comb_weights_grid[-1][0].inspect} (Train : #{$comb_weights_grid[-1][1]} Test : #{$perf_test_grid.mean} / #{$perf_test_svm.mean} )"

if $perf_test_grid.mean > $perf_test_svm.mean
  $comb_weights = $comb_weights_grid[-1][0]
else
  $comb_weights = $comb_weights_svm
end

$cand_set_score = $cand_set.map do |cands|
  cands_new = cands.map{|c|
    c_new = c.dup << c[1..-1].map_with_index{|score,j|
      score * $comb_weights[j]}.sum.r3}
  cands_new[0..0].concat cands_new[1..-1].sort_by{|c|-c[-1]}
end

puts "Generating outputs..."

file_topic = ["topic", $col_id , $o[:new_topic_id]].join("_")
file_qrel =  ["qrel" , $col_id , $o[:new_topic_id]].join("_")

$best_cand = $cand_set_score.map{|cands|cands[1..-1].max{|c1,c2|c1[-1]<=>c2[-1]}[0]}

write_topic(to_path(file_topic), $best_cand.map{|e|{:title=>e}})
write_qrel(to_path(file_qrel), IO.read( to_path($file_qrel) ).split("\n").map_hash_with_index{|e,i|did = e.split(" ")[2] ; [i+1,{did=>1}]})
#}`cp #{to_path($file_qrel)} #{to_pathth(file_qrel)}`
# Text extraction

if $o[:verbose]
  $rltxts = $engine.get_rel_texts($file_qrel) 
  $cand_set_score.each_with_index do |cands,i|
    #next if i > 3 #RedCloth.new(
    cands.each do |c|
      atext = $fields.map_with_index do |field,j|
        $engine.annotate_text_with_query($rltxts[i][1][j], c[0])
      end
      afilename = "doc_#{$rltxts[i][0]}-#{c[0].gsub(" ","_")}.html"
      afilepath = to_path(afilename)
      c << "\"link\":../../doc/#{afilename}"
      File.open(afilepath, "w") do |f|
        f.puts "Query : #{c[0]}"
        $fields.each_with_index do |field,j|
          f.puts "<h3>#{field}: </h3> #{atext[j]}"
        end
      end
    end
  end
end

if $o[:export]
  require 'csv'
  CSV.open(to_path("eval_genquery_#{$query_prefix}_#{$o[:new_topic_id]}.csv"), 'w') do |csv|
    csv << [$fields, "query1", "query2", "pos_man"].flatten
    $cand_set.each_with_index do |cand, i|
      if rand() > 0.5
        q1, q2, pos_man = cand[0][0], cand[1][0], 1
      else
        q1, q2, pos_man = cand[1][0], cand[0][0], 2
      end
      text = $fields.map_with_index{|field,j| "#{$rltxts[i][1][j].gsub("\"", "'").gsub(/^[a-z]+?=\'.*?\'\s*?/im,"")[0..2000]}"}
      csv << [text, q1, q2, pos_man].flatten
    end
  end
end

$i.create_report(binding)
nil
