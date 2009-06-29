bins = [] ; [0,500,1000,2000,5000,10000,1000000].each_cons(2){|e|bins << (e[0]...e[1]) }
rl_docs = i.rl.docs.map{|d|[d.size,d.did]}.group_by{|e|bins.find{|r|r === e[0]}}
aw_docs = i.rs['allwords'].docs.map{|d|[d.size,d.did]}.group_by{|e|bins.find{|r|r === e[0]}}
tbl = [] ; rl = rs = aw = []
tbl = [['SetName' , 'BinStart','BinEnd' ,'Prec' , 'Recall' , 'F1' , 'rl' , 'rl&rs' ,'rs' , 'rl&aw' , 'aw' , 'aw&rs' ,'rl&rs-aw' , 'rl&rs&aw' , 'rl&aw-rs' , 'rs&aw-rl']]
i.rsa.each do |ds|
  if ds.name == 'allwords' then next end
  #Group result set by bins
  rs_docs = ds.docs.group_by{|d|bins.find{|r|r === d.size}}
  tbl_rs = [] ; bins.each do |b|
    rl = rl_docs[b].map{|e|e[1]} ; rs = rs_docs[b].map{|d|d.did} ; aw = aw_docs[b].map{|e|e[1]}
    rl_rs = rl & rs ; rl_aw = rl & aw ; rs_aw = aw & rs ; rra = rl_rs & aw
    begin
      prec = rl_rs.size/rs.size.to_f ; recall = rl_rs.size/rl.size.to_f ; f1 = prec * recall / (prec + recall)
      tbl_rs << [ds.name , b.first , b.last , prec.round_at(4) , recall.round_at(4) , f1.round_at(4) , rl.size , rl_rs.size , rs.size , rl_aw.size , aw.size , rs_aw.size , (rl_rs-rra).size , rra.size , (rl_aw-rra).size , (rs_aw-rra).size]
    rescue
      puts "Zero value in #{ds.name} / #{b}"
    end
  end
  tbl << tbl_rs
end
i.create_report(binding , :name=>$method)
