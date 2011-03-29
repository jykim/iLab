# Find the field mappings for known-item queries
# - correspondance of M.P. estimation and actual occurrence of query-terms
$qs_prm = $i.qsa.find{|e|e[:template]==:prm}
$result = []

# Find query-terms in relevant documents and
# - calc. accuracy of MP estimation
#if (!defined?($mps) || $o[:redo])
$mps, $expected, $actual = [], [], []
$qs_prm.qrys.each_with_index do |q,i|
  info "Query(#{q.qid}) : #{q.text}"
  dflms = [] #Array of Field LMs of Relevent Docs
  $result[i] = [q.qid, q.text].concat($i.qsa.map{|e|e.stat[q.qid.to_s]["map"] if e.stat[q.qid.to_s]})

  #Fetch RelDocs
  rls = $i.rl.docs.find_all{|d|d.qid==q.qid}
  dflm = $dflm[rls.first.did] || ($dflm[rls.first.did] = $engine.get_doc_field_lm(rls.first.did))
  #dflm =  $engine.get_doc_field_lm(rls.first.did)
  if dflm
    rls.each{|rd| dflms << dflm}
  else
    next
  end
  
  # mps = [[field1_name,map_prob],[...]]
  $mps[i] = $engine.get_map_prob(q.text) if !$mps[i]
  #[{field1=>prob, field2=>prob}]
  $actual[i] , $expected[i] = [], []
  $mps[i].each_with_index do |e,j|
    $expected[i][j] = (e[1].size>0)? e[1].sort_by{|k,v|v}.last : nil
    #For every relevant document, find fields that contains query-term then turn this into dist.
    $actual[i][j] = dflms.map{|d| d.find_all{|k,v| v[$engine.kstem(e[0])]}.map{|e2|e2[0]}}.flatten.uniq
    $actual[i][j].concat(["BoW"]) if $actual[i][j].size>0 && $o[:bow_field]
  end#each query-word
end#each query
#end#if

#PRMf
#$sparam = ['method:raw',"node:wsum,method:dirichlet,mu:50"] if $method == 'prmf_test'
#indri_path = ($method == 'prmf_test')? $indri_path_dih : $indri_path


$field_prob = Hash.new(0) #{field1=>prob1, ...}
$init_prob = Hash.new(0) #{field1=>prob1, ...}
$trans_prob = {} #{field1=>{field2=>prob1-2, ...}, ...}
$opt_perf, $opt_perf2, $mp_scores, $fm_ratios = [], [], [], {}
$lambdas = []
$feature_set, $feature_set_test , $actual_set_max = [nil], [nil], []
$mps.each_with_index do |mps, i| #i : query no.
  qid = $offset+i #Assumption : query id starts from 0
  info "== Finding Best Field Combination for Query #{qid} =="
  
  #Build candidate set of field mappings [[f1,f2,...]. [f1,f2]]
  if $actual[i].size > 1
    query_fields = $actual[i].first
    $actual[i].each_with_index{|e,j| query_fields = query_fields.cproduct(e) if j > 0 }
  elsif $actual[i].size == 1
    query_fields = $actual[i].first.map{|e|[e]}
  else
    info "Skipping query #{qid}!"
    next
  end

  #Find Best-performing Field Combination
  actual_set = {} #{field_set=>MAP, ...}
  qs_c, cur_max  = [], 0
  case $o[:train_mode]
  when 'fmap'
    query_fields.each_with_index do |e,j|
      mps_cand = e.map_with_index{|e2,k|[mps[k][0], [[e2, 1.0]]]}.find_all{|mp|mp[1].first.first}
      #puts "[Q#{i+1}] Candidate Fields : #{e.inspect}\n#{mps_cand.inspect}"
      next if mps_cand.size == 0
      qs_c[j] = $i.create_query_set("TEW_#{$query_prefix}_q#{qid}_#{e.join("-")}", :indri_path=>$indri_path, 
                      :template=>:tew, :smoothing=>$sparam, :skip_result_set=>true, :mps=>[mps_cand], :offset=>(qid)) 
      if qs_c[j].stat.size > 0 && qs_c[j].stat['all']['map'] >= cur_max
        cur_max =  qs_c[j].stat['all']['map']
        actual_set[query_fields[j]] = cur_max
        info "[Q#{i+1}] Candidate Fields : #{e.inspect} / map : #{cur_max}"
      end
    end
  when 'dprm'
    lambda_vals = $o[:lambdas] || [0,0.5,1] || [0.0,1.0] || [0,0.25,0.5,0.75,1] || [0,0.2,0,4,0.6,0.8,1.0]
    lambdas_cur = ([1.0]) * mps.size
    0.upto(2) do |t|
      #puts "#{t}th iteration>"
      0.upto(mps.size-1) do |j|
        lambda_vals.each do |lambda|
          lambdas_tmp = lambdas_cur.dup
          lambdas_tmp[j] = lambda
          qs_c << $i.create_query_set("DPRM_#{$query_prefix}_q#{qid}_#{lambdas_tmp.join("-")}", :indri_path=>$indri_path,
                    :template=>:dprm, :smoothing=>$sparam, :skip_result_set=>true, :lambdas=>[lambdas_tmp] , :mps=>[mps], :offset=>(qid)) 
          if qs_c[-1].stat.size > 0 && (qs_c[-1].stat['all']['map'] > cur_max || actual_set.size == 0)
            cur_max =  qs_c[-1].stat['all']['map']
            lambdas_cur = lambdas_tmp.dup
            actual_set[lambdas_cur] = cur_max
            info "[Q#{i+1}|#{t}] lambdas : #{lambdas_tmp.inspect} / map : #{cur_max}"
          end
          #info "[Q#{i+1}|#{t}] lambdas : #{lambdas_tmp.inspect} / map : #{qs_c[-1].stat['all']['map']}"
        end#lambda_val
      end#query_word
    end#iter
    $lambdas << lambdas_cur
  end#case
  $opt_perf << cur_max

  #Find Best DPRM Weight
  
  #Get Field-Map statistics & features
  field_info, feature_set, mp_scores = [], [], []
  dfh = $engine.get_df()
  clm = $engine.get_col_freq(:whole_doc=>true)
  #qry_words = $qs_prm.qrys[i].text
  #info "Query Words : #{qry_words.inspect}"
  #info "MP Words : #{mps.map{|e|e[0]}.inspect}"
  #For each best-performing field combination
  actual_set_max = actual_set.find_all{|k,v|v == actual_set.values.max}.map{|e|e[0]}
  actual_set_max.each_with_index do |actual,k|
    info "Actual Set : #{actual.inspect}"
    features = [] ; right_count = 0
    mps.each_with_index do |mp,j|
      #Feature Lists
      tf  = clm['document'][$engine.kstem(mp[0])] || 1 ; tf = ($o[:fine_bin])? Math.log10(tf).round : (tf>100)
      idf = dfh[$engine.kstem(mp[0])] || 1 ; idf = ($o[:fine_bin])? Math.log10(idf).round : (idf>500)
      qry_word = mp[0]# $engine.unstem(mp[0],qry_words)
      capital = ( qry_word == mp[0].capitalize)? "CapT" : "capf"
      upper = ( qry_word == mp[0].upcase)? "UPT" : "upf"
      high_field = mp[1].sort_by{|e|e[1]}[-1]
      if $o[:fine_bin] #fine-grained binning for MP feature
        mp_set = $fields.map{|f|v = mp[1].map_hash{|e|e}[f] ; ((v)? (v/0.1).round.to_s : "0")}
      else
        mp_set = $fields.map{|f|v = mp[1].map_hash{|e|e}[f] ; (f[0..2]||"nil") + ((v && v>0.3)? ((v>0.6)? "H" : "m") : "l")}
      end
      
      #Information for Reporting
      field_info << [mp[0], $expected[i][j], actual[j]]
      right_count += 1 if actual[j] == $expected[i][j][0]
      
      #Combine into a file
      case $o[:train_mode]
      when 'fmap'
        if actual[j]
          features << [mp[0], tf, idf, capital, upper, high_field[0], (high_field[1]/0.1).round.to_s].concat(mp_set).push(actual[j])
        end
      when 'dprm'
        features << [mp[0], tf, idf, capital, upper, high_field[0], (high_field[1]/0.1).round.to_s].concat(mp_set).push(actual[j])
      end
    end#query-word
    feature_set << features
    mp_scores << right_count / mps.find_all{|e|e[1].size>0}.size.to_f
  end#field-candidates
  $actual_set_max << actual_set_max.last
  $feature_set << (($o[:single_set])? feature_set[-1..-1] : feature_set)
  $feature_set_test << feature_set.first
  case $o[:train_mode]
  when 'fmap'
    $mp_scores << mp_scores.mean.r3
    fm_ratios = actual_set_max.flatten.group_by{|e|e}.map{|k,v|[k,v.size]}.sort_by{|e|e[1]}.reverse.to_p
    $fm_ratios[i] = fm_ratios
    $result[i]<< cur_max << mp_scores.mean.r3 << fm_ratios.map{|e|[e[0],e[1].r3].join(":")}.join(" ") << #fm_ratios[0][0] << fm_ratios[0][1] << 
      field_info.group_by{|e|e[0]}.map{|k,v|"#{k} (#{v[0][1][0]}#{v[0][1][1].r1}->#{v.map{|e|e[2]}.uniq.join(' ')})"}.join(" ")    
  when 'dprm'
    $result[i]<< cur_max << mps.map_with_index{|e,j|"#{e[0]} (#{lambdas_cur[j]})"}.join(" ")
  end
end#query
$query_len = $mps.map{|e|e.size}

if $o[:train_crf]
  # CRF training for MP estimation
  info "CRF training(#{$o[:train_mode]}) started..."
  #Setup for Cross-validation
  if $o[:cval_no]
    $param_opt = ARGV[1] if ARGV[1]
    $method = 'cval'
    $range_test = get_cval_range($offset, $count, $o[:cval_no], $o[:cval_id])
    $cval_id = "CV#{$o[:cval_id]}-#{$o[:cval_no]}"
    $remark += $cval_id
    # $range_tune = get_cval_range($offset, $count, $o[:cval_no], (($o[:cval_no]==$o[:cval_id]+1)? 0 : $o[:cval_id]+1))
    info("Cross Validation #{$o[:cval_id]} with range #{$range_test}")
    info("param_opt = #{$param_opt}") if $param_opt
  elsif $o[:range_test]
    $range_test = $o[:range_test]
  end

  input_train = $o[:train_file] || "crf_train_#{$col_id}_#{$o[:train_mode]}_#{$o[:topic_id]}_#{$remark}.in"
  input_test = "crf_test_#{$col_id}_#{$o[:train_mode]}_#{$o[:topic_id]}_#{$remark}.in"
  model = "crf_model_#{$col_id}_#{$o[:train_mode]}_#{$o[:topic_id]}_#{$remark}.in"

  if $o[:cval_no] || $o[:range_test]
    i = -1
    o_qs = $o.merge(:offset=>($range_test.first))
    $i.fwrite(input_train , $feature_set.find_all{|e|i+=1 ; puts i ; i>0 && !($range_test===i)}.collapse.map{|e|e.map{|e2|e2.join(" ")}.join("\n")}.join("\n\n"))
    $i.fwrite(input_test  , $feature_set_test[$range_test].map{|e|e.map{|e2|e2.join(" ")}.join("\n")}.join("\n\n"))
  else
    o_qs = $o
    $i.fwrite(input_train , $feature_set.collapse.find_all{|e|e}.map{|e|e.map{|e2|e2.join(" ")}.join("\n")}.join("\n\n"))
    $i.fwrite(input_test  , $feature_set_test.find_all{|e|e}.map{|e|e.map{|e2|e2.join(" ")}.join("\n")}.join("\n\n"))  
  end

  $crf = CRFInterface.new
  $crf.train(input_train, model, $o)
  $qs_crf = run_cprm_query(input_test,  model, o_qs)
  $r[:result] = $qs_crf.stat['all']['map']
  $result_crf = [['QID','Query','PRM','CRF','FieldMapping']]
  $qs_prm.qrys.find_all{|q|$range_test === q.qid}.each_with_index do |q,i|
    #puts q.qid
    train_result = case $o[:train_mode]
    when 'fmap'
      $qs_crf[:mps][i].map{|e|[e[0],e[1].sort_by{|e2|e2[1]}.reverse].inspect}.join("<br>")
    when 'dprm'
      $qs_crf[:lambdas][i].inspect
    end
    $result_crf << [q.qid, q.text, $qs_prm.stat[q.qid.to_s]['map'], $qs_crf.stat[q.qid.to_s]['map'], train_result]
  end
  `cp #{to_path(input_train)} #{to_path('data_'+input_train+".txt")}`
  `cp #{to_path(input_test+".out")} #{to_path('data_'+input_test+".out.txt")}`
end

$i.create_report(binding)
nil
