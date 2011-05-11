#topic_types = ['D_RN','D_TF','D_IDF','D_TIDF','F_RN_RN','F_RN_TF','F_RN_IDF','F_RN_TIDF']
$ret_models = $i.qsa.map{|qs|qs[:template]}.uniq
$i.qsa.map{|e| `cp #{to_path(e.name+'.qry')} #{to_path('qry_'+e.name+'.txt')}`}
$qrys = $i.qsa[0].qrys
$tbl_qry = [['qid', 'text']].concat($qrys.map{|q|[q.qid,q.text]}).concat([["%","%"]])

$tbl_all = [['Measure','map','P5','P10','P20']]
$tbl_all.concat $i.qsa.map{|qs|["\"#{qs.short_name}\":#{'qry_'+qs.name+'.txt'}"].concat($tbl_all[0][1..-1].map{|e|qs.stat['all'][e]})}
#debugger
if $o[:verbose]
  
  $tbl_qry.add_cols $i.qsa.map{|e|e.short_name = e.name.gsub($query_prefix+'_',"")}, 
    $qrys.map{|q|$i.qsa.map{|e|(e.stat[q.qid.to_s])? e.stat[q.qid.to_s]['map'] : 0.0}}
  if $o[:verbose] == :mp
    $mprel = $engine.get_mpset_from_flms($queries, $rlflms1)
    #$mpres = $engine.get_mpset_from_flms($queries, $rsflms)
    puts "[exp_perf] MPs calculated from RelDocs..."
    $mpcol = $engine.get_mpset($queries)
    #$mpcol_df = $engine.get_mpset(queries, :df=>true)
    puts "[exp_perf] MPs calculated from Collection..."
    
    #$tbl_qry.add_diff_col(6, 3, :title=>"Ora-PRMS")

    if $method == 'final'
      $tbl_qry.add_diff_col(4, 3, :title=>"PRMS-MFLM")
      $tbl_qry.add_diff_col(5, 4, :title=>"Mix-PRMS")
      $tbl_qry.add_diff_col(6, 5, :title=>"Ora-Mix")

      $mpmix_h = $mpmix.map{|e|$engine.marr2hash e}
      $mp_mflm = $engine.get_mixture_mpset($queries, [:prior], [1.0]).
        map{|e|$engine.marr2hash e}

      # Aggregate KL-divergence (sum term-wise scores)
      $tbl_qry.add_cols "DKL", $engine.get_mpset_klds( $mprel, $mp_mflm ), :round_at=>3
      $tbl_qry.add_cols "DKL(p)", $engine.get_mpset_klds( $mprel, $mpcol ), :round_at=>3
      $tbl_qry.add_cols "DKL(m)", $engine.get_mpset_klds( $mprel, $mpmix_h ), :round_at=>3
      #$tbl_qry.add_diff_col(11, 10, :title=>"DiffDKL")
      $tbl_qry.add_cols "Cos", $engine.get_mpset_cosine( $mprel, $mp_mflm ), :round_at=>3
      $tbl_qry.add_cols "Cos(p)", $engine.get_mpset_cosine( $mprel, $mpcol ), :round_at=>3
      $tbl_qry.add_cols "Cos(m)", $engine.get_mpset_cosine( $mprel, $mpmix_h ), :round_at=>3
      #$tbl_qry.add_diff_col(14, 13, :title=>"DiffCOS")
      $tbl_qry.add_cols "P@1", $engine.get_mpset_prec( $mprel, $mp_mflm ), :round_at=>3
      $tbl_qry.add_cols "P@1(p)", $engine.get_mpset_prec( $mprel, $mpcol ), :round_at=>3
      $tbl_qry.add_cols "P@1(m)", $engine.get_mpset_prec( $mprel, $mpmix_h ), :round_at=>3
      #$tbl_qry.add_diff_col(17, 16, :title=>"DiffPrec")
    end
    puts "[exp_perf] table values calculated..."
  end
  
  $rpt_filename = "rpt_#{$col}_#{$o[:topic_id]}_#{$method}.tsv"
  $tbl_qry.export_tbl(to_path($rpt_filename))

  $sig_test, $log_reg = {}, {}
  if false # $i.check_R()
    $i.qsa.map{|qs|qs.name}.to_comb.each_with_index do |qs,i|
      $log_reg[qs.join]  = $i.log_reg(qs[0], qs[1], $tbl_qry) if $o[:logreg]
      $sig_test[qs.join] = $i.sig_test(qs[0], qs[1])
    end
  else
    err "R is not found!"
  end

  #$plots_bar = {}
  #$plots_point = {}
  #$i.qsa.map{|qs|qs.name}.to_comb.each do |qs|
  #  #puts qs
  #  data_bar = []
  #  data_point = []
  #  next if $i.qs[qs[0]].stat.size != $i.qs[qs[1]].stat.size
  #  $i.qsa[0].qrys.each do |q|
  #    #puts  q.qid
  #    next if $i.qs[qs[0]].stat[q.qid.to_s] == nil
  #    data_point << [$i.qs[qs[0]].stat[q.qid.to_s]['map'] , $i.qs[qs[1]].stat[q.qid.to_s]['map']]
  #    data_bar << [q.qid , data_point.last[0] - data_point.last[1]]
  #  end
  #  $plots_bar[qs.join] = [{:label=>"MAP Difference (#{qs[0]}-#{qs[1]})" , :data=>data_bar.map{|e|e[1]}.sort.reverse , :with=>'impulses'}]
  #  $plots_point[qs.join] = [{:label=>"MAP Distribution (#{qs[0]},#{qs[1]})" , :data=>data_point , :with=>'points'}]
  #end
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
