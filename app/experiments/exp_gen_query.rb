
# Get the Training Results
$rlflms = $engine.get_rel_flms($file_qrel, 2) if !$rlflms
$rlfvs = $engine.get_rel_fvs($file_qrel) if !$rlfvs
#$engine.train_mixture_weights($queries, $rlflms)
$engine.train_trans_probs($queries, $rlflms1) if !$trans

puts "Generate candidates..."
$cand_set = $engine.generate_candidates($queries, $rlflms, $rlfvs, $o) #if !$cand_set
puts "Training weights..."
$comb_weights = $engine.train_comb_weights($cand_set)
puts "Weights trained : #{$comb_weights[-1][0].inspect}"
$cand_set.map! do |cands|
  cands_new = cands.map{|c|
    c << c[2..-1].map_with_index{|score,j|
      score * $comb_weights[-1][0][j]}.sum.r3}
  cands_new[0..0].concat cands_new[1..-1].sort_by{|c|-c[-1]}
end

file_topic = ["topic", $col_id , $o[:new_topic_id]].join("_")
file_qrel =  ["qrel" , $col_id , $o[:new_topic_id]].join("_")

$best_cand = $cand_set.map{|cands|cands[1..-1].max{|c1,c2|c1[-1]<=>c2[-1]}[0]}

write_topic(to_path(file_topic), $best_cand.map{|e|{:title=>e}})
write_qrel(to_path(file_qrel), IO.read( to_path($file_qrel) ).split("\n").map_hash_with_index{|e,i|did = e.split(" ")[2] ; [i+1,{did=>1}]})
#}`cp #{to_path($file_qrel)} #{to_path(file_qrel)}`
# Text extraction

if $o[:verbose]
  $rltxts = $engine.get_rel_texts($file_qrel) 
  $cand_set.each_with_index do |cands,i|
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

$i.create_report(binding)
nil
