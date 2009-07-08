#topic_types = ['D_RN','D_TF','D_IDF','D_TIDF','F_RN_RN','F_RN_TF','F_RN_IDF','F_RN_TIDF']
$i.qsa.map{|e| `cp #{to_path(e.name+'.qry')} #{to_path('qry_'+e.name+'.txt')}`}
$tbl_qry = []
$tbl_qry << ['qid', 'text' , $i.qsa.map{|e|e.short_name = e.name.gsub($query_prefix+'_',"")}, 'rdoc', CS_TYPES, CS_TYPES] #', topic_types, word_cnt', 'no_rel', 'no_res', 'len_rel', 'stdev_len_rel',
$tbl_qry[0] << topic_types if $o[:gen_prob]
if $o[:verbose]
  #Length Stat
  #$i.calc_length_stat

  #Perform. Stat
  $i.fetch_data if $i.rl

  #Stat (e.g. MAP)
  #$i.calc_stat

  doc_no = $engine.get_col_stat()[:doc_no] if $o[:gen_prob]
  $i.qsa[0].qrys.each do |q|
    next if $i.qsa[0].stat[q.qid.to_s] == nil
    did_rl = q.rl.docs[0].did
    #dno_rl = $engine.to_dno(q.rl.docs[0].did) if $o[:gen_prob]
    #gen_probs = topic_types.map{|topic_type| $engine.get_gen_prob(q.text, dno_rl , topic_type, :doc_no=>doc_no) }

    #word_cnt = q.text.split(' ').size
    #\len_res_docs = q.rs.docs.map{|e|e.size}.mean
    #no_rel_docs, no_res_docs= q.rl.docs.size , q.rs.docs.size
    #len_rel_docs = (q.rl.docs.size>0)? q.rl.docs.map{|e|e.size}.mean : -1.0
    #stdev_len_rel_docs = (q.rl.docs.size>0)? q.rl.docs.map{|e|e.size}.stdev : -1.0
    $tbl_qry << [q.qid, q.text ,$i.qsa.map{|e|e.stat[q.qid.to_s]['map']}, did_rl , 
      CS_TYPES.map{|e|did_rl.scan(to_ext($top_cols[q.text][e][0])).size}, CS_TYPES.map{|e|$top_cols[q.text][e].join(":")}] #, gen_probs, word_cnt, no_rel_docs, no_res_docs, len_rel_docs.r2, stdev_len_rel_docs.r2,
    $tbl_qry.last << gen_probs if $o[:gen_prob]
  end
  $sig_test, $log_reg = {}, {}
  if $i.check_R()
    $i.qsa.map{|qs|qs.name}.to_comb.each_with_index do |qs,i|
      $log_reg[qs.join]  = $i.log_reg(qs[0], qs[1], $tbl_qry) if $o[:logreg]
      $sig_test[qs.join] = $i.sig_test(qs[0], qs[1])
    end
  else
    err "R is not found!"
  end

  $plots_bar = {}
  $plots_point = {}
  $i.qsa.map{|qs|qs.name}.to_comb.each do |qs|
    #puts qs
    data_bar = []
    data_point = []
    next if $i.qs[qs[0]].stat.size != $i.qs[qs[1]].stat.size
    $i.qsa[0].qrys.each do |q|
      #puts  q.qid
      next if $i.qs[qs[0]].stat[q.qid.to_s] == nil
      data_point << [$i.qs[qs[0]].stat[q.qid.to_s]['map'] , $i.qs[qs[1]].stat[q.qid.to_s]['map']]
      data_bar << [q.qid , data_point.last[0] - data_point.last[1]]
    end
    $plots_bar[qs.join] = [{:label=>"MAP Difference (#{qs[0]}-#{qs[1]})" , :data=>data_bar.map{|e|e[1]}.sort.reverse , :with=>'impulses'}]
    $plots_point[qs.join] = [{:label=>"MAP Distribution (#{qs[0]},#{qs[1]})" , :data=>data_point , :with=>'points'}]
  end
end
 
if $o[:env]
  $r['map'] = $i.qs.map_hash{|k,v| [k ,v.stat['all']['map']] }
  $r['recip_rank'] = $i.qs.map_hash{|k,v| [k ,v.stat['all']['recip_rank']] }
  #$r['P10'] = $i.qs.map_hash{|k,v| [k ,v.stat['all']['P10']] }
  #$r['P30'] = $i.qs.map_hash{|k,v| [k ,v.stat['all']['P30']] }
  #$r['P100'] = $i.qs.map_hash{|k,v| [k ,v.stat['all']['P100']] }
end

$i.create_report(binding)
nil