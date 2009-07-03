#$i.calc_stat
$i.calc_length_stat
plot = []
plot << {:label => 'Collection' , :data => $i.ldist }
plot << {:label => 'Relevant' , :data => $i.rl.docs.find_all{|d|d.relevance > 0}.map{|d|d.size}.to_dist(100).to_p }
#i.rsa.each do |ds|
#  plot << {:label => 'Result - '+ds.name , :data => ds.ldist.to_p}
#end

plot_cum = plot.map{|e| e.merge(:data=>e[:data].to_a.to_cum) }

=begin
avg_len_rank = []
$i.rsa.each do |ds|
  avg_len_rank << {:label=>ds.name , :data=>ds.docs.map{|d|[d.rank,d.size]}.group_by{|e|e[0]}.map_hash{|k,v|[k , v.map{|e|e[1]}.mean ] } }
end

avg90_len_rank = []
$i.rsa.each do |ds|
  avg90_len_rank << {:label=>ds.name , :data=>ds.docs.map{|d|[d.rank,d.size]}.group_by{|e|e[0]}.map_hash{|k,v|[k , v.map{|e|e[1]}.mean(:exclude=>0.1) ] } }
end
median_len_rank = []
$i.rsa.each do |ds|
  median_len_rank << {:label=>ds.name , :data=>ds.docs.map{|d|[d.rank,d.size]}.group_by{|e|e[0]}.map_hash{|k,v|[k , v.map{|e|e[1]}.median ] } }
end

prec_rank = []
$i.rsa.each do |ds|
  prec_rank << {:label=>ds.name , :data=>ds.docs.map{|d|[d.rank,d.relevance>0]}.group_by{|e|e[0]}.map_hash{|k,v|[k , v.find_all{|e|e[1]==true}.size/v.size.to_f ] } }
end
=end

test_rank = if $topk
              [$topk]
            else
              [100]
            end

=begin
#Precision by binning documents
prec_len = []
$i.rs.each do |k,v|
  prec_len << {:label=>k , :with=>'points' , :data=>v.docs.sort_by{|d|d.size}.
    map{|d|[d.size,d.relevance>0]}.in_groups_of(1000).find_all{|e|e.size == 1000}.
    map{|e|[e.map{|s|s[0]}[500].to_f , e.find_all{|r|r[1]==true}.size/e.size.to_f ] } }
end
=end

rs_topk = {}
plot_topk = {} 
plot_cum_topk = {} 
prec_len_topk = {} ; recall_len_topk = {} ; f1_len_topk = {}
test_rank.each do |n|
  rs_topk[n] = []
  plot_topk[n] = []
  #Length Dist. for top K
  $i.rsa.each_with_index do |ds,idx|
    rs_topk[n][idx] = DocumentSet.create_by_filter(ds.name+'_top'+n.to_s , ds){|d|d.rank <= n}
    plot_topk[n] << {:label => 'Result - ' + ds.name , :data => rs_topk[n][idx].ldist.to_p}
  end
  plot_cum_topk[n] = plot_topk[n].map{|e| e.merge(:data=>e[:data].to_a.to_cum) }
  plot_topk[n].concat plot[0..1]
  plot_cum_topk[n].concat plot_cum[0..1]

  #Prec. by Len. for Top K
  prec_len_topk[n] = []
  rs_topk[n].each do |ds|
    prec_len_topk[n] << {:label=>ds.name , :data=>ds.docs.map{|d|[d.size,d.relevance>0]}.group_by{|e|e[0]/100}.map_hash{|k,v|[k*100 , v.find_all{|e|e[1]==true}.size/v.size.to_f ] if v.size > 25} }
  end

  #Recall by Len. for Top K
  recall_len_topk[n] = []
  ldist_rl = $i.rl.docs.find_all{|d|d.relevance>0}.map{|d|[d.did , d.size]}.group_by{|e|e[1]/100}
  rs_topk[n].each do |ds|
    recall_len_topk[n] << {:label=>ds.name , :data=>ldist_rl.map_hash{|k,v|[k*100 , (v.map{|e|e[0]} & ds.dh.keys).size / v.size.to_f ] if v.size > 25} }
  end

  #F1
  f1_len_topk[n] = []
  rs_topk[n].each_with_index do |ds,j|
    f1_len_topk[n] << {:label=>ds.name , :data=>prec_len_topk[n][j][:data].map_hash{|k,p| r = recall_len_topk[n][j][:data][k] ; [k , p * r / (p + r)] if r}}
  end

end

$i.create_report(binding)
nil

