
$tbl_qry = []
$tbl_qry << ['qid', 'text',  $i.qsa.map{|e|e.name}] #'word_cnt', 'no_rel', 'no_res', 'len_rel', 'stdev_len_rel',
$i.qsa[0].qrys.each do |q|
  next if $i.qsa[0].stat[q.qid.to_s] == nil
  word_cnt = q.text.split(' ').size
  no_rel_docs, no_res_docs= q.rl.docs.size , q.rs.docs.size
  $tbl_qry << [q.qid, q.text, $i.qsa.map{|e|e.stat[q.qid.to_s]['map']}] #word_cnt, no_rel_docs, no_res_docs, len_rel_docs.r2, stdev_len_rel_docs.r2,
end