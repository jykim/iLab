=begin
=end

count_len = []
i.rsa.each do |ds|
  #if k != 'rel' then next end
  count_len << {:label=>ds.name , :data=>ds.docs.map{|d|[d.size,d.relevance>0]}.group_by{|e|e[0]/100}.map_hash{|k,v|[k*100 , v.find_all{|e|e[1]==true}.size ] if v.size > 25} }
end

prec_len = []
i.rsa.each do |ds|
  #if k != 'rel' then next end
  prec_len << {:label=>ds.name , :data=>ds.docs.map{|d|[d.size,d.relevance>0]}.group_by{|e|e[0]/100}.map_hash{|k,v|[k*100 , v.find_all{|e|e[1]==true}.size/v.size.to_f ] if v.size > 25} }
end

recall_len = []
ldist_rl = i.rl.docs.find_all{|d|d.relevance>0}.map{|d|[d.did , d.size]}.group_by{|e|e[1]/100}
i.rsa.each do |ds|
  recall_len << {:label=>ds.name , :data=>ldist_rl.map_hash{|k,v|[k*100 , (v.map{|e|e[0]} & ds.dh.keys).size / v.size.to_f ] if v.size > 10} }
end
#=end
i.create_report(binding , :name=>$method)
