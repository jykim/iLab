#bins = [] ; [0,500,1000,2000,5000,10000,1000000].each_cons(2){|e|bins << (e[0]...e[1]) }
bins = [] ; [0,1000000].each_cons(2){|e|bins << (e[0]...e[1]) }
rl_docs = i.rl.docs.find_all{|d|d.relevance>0}.map{|d|[d.size,d.did,d.relevance]}.group_by{|e|bins.find{|r|r === e[0]}}

tbl = [] ; rl = rs = []



#For each result set
rs_con = ResultDocumentSet.new('rs_con') ; con_docs = []
i.rsa.each_with_index do |ds , j|
  if j == 0
    con_docs = ds.docs.find_all{|d| d.rank < $topk }
  else
    docs = ds.docs.find_all{|d| d.rank < $topk }.map_hash{|d| [d.did,d]}
    con_docs.delete_if{|d| !docs[d.did]}
  end
end
rs_con.import_docs(con_docs)
con_docs_size = con_docs.group_by{|d|d.qid}.map_hash{|k,v|[k,v.size]}
i.rsa << rs_con

puts "Size of rs_con : #{con_docs.size}"

#For each result set
i.rsa.each_with_index do |ds,j|
  #Group result set by bins, after selecting TopK docs
  if j == i.rsa.size-1
    rs_docs = ds.docs.group_by{|d|bins.find{|r|r === d.size}}
  else
    rs_docs = ds.docs.find_all{|d| d.rank <= con_docs_size[d.qid] }.group_by{|d|bins.find{|r|r === d.size}}
  end
  tbl_rs = [] ; tbl_rs = [['SetName' , 'BinStart','BinEnd' ,'Prec' , 'Recall' , 'F1' , 'rl' , 'rl&rs' ,'rs']]
  bins.each do |b|
    rl = rl_docs[b].map{|e|[e[1],e[2]]} ; rs = rs_docs[b].map{|d|[d.did , d.relevance]}
    rl_rs = rl & rs
    begin
      prec = rl_rs.size/rs.size.to_f ; recall = rl_rs.size/rl.size.to_f ; f1 = prec * recall / (prec + recall)
      tbl_rs << [ds.name , b.first , b.last , prec.round_at(4) , recall.round_at(4) , f1.round_at(4) , rl.size , rl_rs.size , rs.size]
    rescue
      puts "Zero value in #{ds.name} / #{b}"
    end
  end
  tbl << tbl_rs
end
i.create_report(binding , :name=>$method)
