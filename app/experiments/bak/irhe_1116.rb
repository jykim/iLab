#if !defined?(plot) || !plot
plot = [{:label => 'Result - ql' , :data => i.rs['ql'].ldist.to_p}]
plot << {:label => 'Result - dm' , :data => i.rs['dm'].ldist.to_p} if i.rs['dm']
plot << {:label => 'Collection' , :data => i.ldist }
plot << {:label => 'Relevant' , :data => i.rl.docs.find_all{|d|d.relevance > 0}.map{|d|d.size}.to_dist(100).to_p }
#end

=begin
#if !defined?(rs_topk) || !rs_topk
#end
=end

prec_len = []
i.rs.each do |k,v|
  prec_len << {:label=>k , :with=>'points' , :data=>v.docs.sort_by{|d|d.size}.
    map{|d|[d.size,d.relevance>0]}.in_groups_of(1000).find_all{|e|e.size == 1000}.
    map{|e|[e.map{|s|s[0]}[500].to_f , e.find_all{|r|r[1]==true}.size/e.size.to_f ] } }
end

prec_len2 = [] ; count_by_len = {}
i.rs.each do |k,v|
  count_by_len[k] = Hash.new(0)
  prec_len2 << {:label=>k , :data=>v.docs.map{|d|[d.size,d.relevance>0]}.group_by{|e|e[0]/100}.map_hash{|k2,v2|count_by_len[k][k2] = v2.find_all{|e|e[1]==true}.size ; [k2*100 , count_by_len[k][k2]/v2.size.to_f ] if v2.size > 25} }
end

recall_len2 = []
i.rs.each do |k,v|
  rs_docs = i.rs[k].dh.keys
  recall_len2 << {:label=>k , :data=>i.rl.docs.find_all{|d|d.relevance>0}.map{|d|[d.did , d.size]}.group_by{|e|e[1]/100}.map_hash{|k2,v2|[k2*100 , (v2.map{|e|e[0]} & rs_docs).size / v2.size.to_f ] if v2.size > 10} }
end


=begin
done_rl = false
i.qs.each do |k,v|
  v.qrys.each do |q| 
    q.text.split.each do |w| 
      i.rs[k].add_index_term( q.qid , w)
      i.rl.add_index_term( q.qid , w) if !done_rl
    end
  end
  done_rl = true
end

allwords_len2 = []
i.rs.each do |k,v|
  allwords_len2 << {:label=>k , :data=>v.docs.map{|d|[d.size,d.all_idx_words==true]}.group_by{|e|e[0]/100}.map_hash{|k2,v2| [k2 , v2.find_all{|e|e[1]==true}.size / k2.to_f ] if v2.size > 25} }
end
=end

i.create_report(binding , :name=>'irhe_1116')
nil
