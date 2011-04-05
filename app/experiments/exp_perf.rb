#topic_types = ['D_RN','D_TF','D_IDF','D_TIDF','F_RN_RN','F_RN_TF','F_RN_IDF','F_RN_TIDF']
$ret_models = $i.qsa.map{|qs|qs[:template]}.uniq
$i.qsa.map{|e| `cp #{to_path(e.name+'.qry')} #{to_path('qry_'+e.name+'.txt')}`}
$qrys = $i.qsa[0].qrys
$tbl_qry = [['qid', 'text']].concat($qrys.map{|q|[q.qid,q.text]}).concat([["%","%"]])

$tbl_all = [['Measure','map','P5','P10','P20']]
$tbl_all.concat $i.qsa.map{|qs|["\"#{qs.short_name}\":#{'qry_'+qs.name+'.txt'}"].concat($tbl_all[0][1..-1].map{|e|qs.stat['all'][e]})}
#debugger
if $o[:verbose]
  #Length Stat
  #$i.calc_length_stat
  #debugger
  #Perform. Stat
  $i.fetch_data if $i.rl

  #Stat (e.g. MAP)
  $i.calc_stat

  #$tbl_qry[0] << topic_types if $o[:gen_prob]
  #doc_no = $engine.get_col_stat()[:doc_no] if $o[:gen_prob]
  #gen_probs = topic_types.map{|topic_type| $engine.get_gen_prob(q.text, dno_rl , topic_type, :doc_no=>doc_no) }
  
  $did_rl = $qrys.map_hash{|q|[q.qid, q.rl.docs[0].did]}
  #$col_rl = $qrys.map_hash{|q|[q.qid, did_to_col_type($did_rl[q.qid])]}
  #
  #$tbl_qry.add_cols CSEL_TYPES.map{|e|"r#{e}"}, 
  #  $qrys.map{|q|CSEL_TYPES.map{|e|$did_rl[q.qid].scan(to_ext($csel_scores[q.qid][e].r3.to_a.sort_val[0][0])).size}}
  #
  #$tbl_qry.add_cols CSEL_TYPES.map{|e|"s#{e}"}, 
  #$qrys.map{|q|CSEL_TYPES.map{|e|$csel_scores[q.qid][e][$col_rl[q.qid]].r3}}
  #  
  $tbl_qry.add_cols $i.qsa.map{|e|e.short_name = e.name.gsub($query_prefix+'_',"")}, 
    $qrys.map{|q|$i.qsa.map{|e|(e.stat[q.qid.to_s])? e.stat[q.qid.to_s]['map'] : 0.0}}
    
  if $o[:verbose] == :mp
    $mprel = $engine.get_mpset_from_flms($queries, $rlflms)
    $mpres = $engine.get_mpset_from_flms($queries, $rsflms)
    $mpcol = $engine.get_mpset($queries)
    #$mpcol_df = $engine.get_mpset(queries, :df=>true)
    #$tbl_qry.add_cols "MPrel", $mprel.map{|e|e.map{|k,v|"[#{k}] "+v.print}.join("<br>")}, :summary=>:none
    #$tbl_qry.add_cols "MPcol", $mpcol.map{|e|e.map{|k,v|"[#{k}] "+v.print}.join("<br>")}, :summary=>:none
    # Aggregate KL-divergence (sum term-wise scores)
    #$tbl_qry.add_cols "D_KL", $engine.get_mpset_klds( $mprel, $mpcol )
    $tbl_qry.add_cols "D_KL(rs)", $engine.get_mpset_klds( $mprel, $mpres )
    $tbl_qry.add_cols "D_KL(df)", $engine.get_mpset_klds( $mprel, $mpcol_df )
  end

  #$tbl_qry.add_cols $ret_models, $ret_models.map{|e|$avg_doc_scores[q.qid][e].to_p[$col_rl[q.qid]].r3}
  
  #$tbl_qry << ["AVG" , "PERF" , (2..9).to_a.map{|i|$tbl_qry[1..-1].avg_col(i).r3}].flatten
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
