
if $method=='test'
  test_qids = [702]
else
  test_qids = $i.qsa[0].qrys.find_all{|q| !$o[:range] || $o[:range].include?(q.qid)}.map{|q|q.qid}
end


=begin
#Query-wise Analysis
qw_set = {}
test_qids.each do |q|
  qw_set[q] = {}
  $i.rs.each do |k,v|    
    qw_set[q][k] = {}
    docs_rs = $i.rs[k].dhq[q].map{|d|d.did}
    qw_set[q][k][:rs] = docs_rs
    
    docs_rl = ($i.rl.docs.size>0 && $i.rl.dhq[q])? $i.rl.dhq[q].find_all{|d|d.relevance > 0}.map{|d|d.did} : []
    qw_set[q][k][:tp] = docs_rs & docs_rl
    qw_set[q][k][:fp] = docs_rs - docs_rl # wrong result
    qw_set[q][k][:fn] = docs_rl - docs_rs # missing answer
  end
end
=end

$i.create_report(binding)
nil
