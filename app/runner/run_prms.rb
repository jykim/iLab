load 'app/ilab.rb'
load 'app/adhoc/pd_lib.rb'
load 'app/runner/run_prms_helper.rb'

init_env()
init_collection($col)
set_collection_param($col_id)

def get_rsflms(qs, o = {})
  topk = o[:topk] || 5
  qs.qrys.map_with_index{|q,i|
    puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
    $engine.get_res_flm q.rs.docs[0..topk]} 
end

def get_rslms(qs, o = {})
  topk = o[:topk] || 10
  qs.qrys.map_with_index{|q,i|
    puts "[get_res_lm] #{i}th query processed" if i % 10 == 1
    $engine.get_res_lm q.rs.docs[0..topk]} 
end

def get_rm_queries(rslms, term_no = 50)
  rslms.map{|rslm|
    rslm.find_all{|w,p|!$stopwords.include?(w)}.sort_by{|e|e[1]}.reverse[0..term_no]}
end

#Choose Retrieval Method
#def ILabLoader.build(ilab)
begin
  puts "METHOD : #$method"
  $sparam = $sparam_prm = $sparam_mflm = $o[:sparam] if $o[:sparam] ### INDRI SCORING TEST ###
  o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam_prm)
  $mp_types = $o[:mp_types] || [:cug, :rug, :cbg, :prior, :rbg ]
  case $method
  when 'final'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>$sparam_mflm, :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o.merge(:smoothing=>$sparam_prm))
    
    $rsflms = get_rsflms(qs) if !$rsflms
    $mpmix = $engine.get_mixture_mpset($queries, $mp_types, $mix_weights)
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx_#{$o[:mp_types]}", 
      o.merge(:template=>:tew, :mps=>$mpmix, :smoothing=>$sparam_prm ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:flms=>$rlflms1, :smoothing=>$sparam_prm))
    #$i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:template=>:tew, :mps=>$engine.get_mixture_mpset($queries, [:ora2], [1]), :smoothing=>$sparam_prm ))

  when 'param_rm_prms'
    $mp_types = $o[:mp_types] || [:cug]
    $mix_weights = [1.0]
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $rsflms = get_rsflms(qs) if !$rsflms
    $mpmix = $engine.get_mixture_mpset($queries, $mp_types, $mix_weights)
    $queries_rm = get_rm_queries(get_rslms(qs)) if !$queries_rm
    $mpmix_rm = $engine.get_mixture_mpset($queries_rm, $mp_types, $mix_weights)

    [0.1, 0.2, 0.3, 0.5, 0.7, 0.9].each do |lambda|
      $i.crt_add_query_set("#{$query_prefix}_PRMSmxRM_#{$o[:mp_types]}_l#{lambda}", 
        o.merge(:template=>:tew_rm, :mps=>$mpmix, :mps_rm=>$mpmix_rm, :smoothing=>$sparam_prm, :lambda=>lambda ))
    end

  when 'param_rm'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $queries_rm = get_rm_queries(get_rslms(qs)) if !$queries_rm

    [0.05, 0.1, 0.15, 0.2, 0.3, 0.5, 0.7, 0.9].each do |lambda|
      $i.crt_add_query_set("#{$query_prefix}_RM_l#{lambda}", 
        o.merge(:template=>:rm, :rm_topics=>$queries_rm, :smoothing=>$sparam_prm, :lambda=>lambda ))
    end
  
  when 'param_bm25f'
    $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $bm25f_smt = IndriInterface.get_field_bparam($fields , $bfs, $k1)
    $i.crt_add_query_set("#{$query_prefix}_BM25F", :template=>:hlm, :smoothing=>$bm25f_smt, 
                            :hlm_weights=>($bm25f_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
  
  when 'pmix_var'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)    
    $rsflms = get_rsflms(qs) if !$rsflms
    $mpmix2 = $engine.get_mixture_mpset($queries, [:rug], [1])
    $mpmix3 = $engine.get_mixture_mpset($queries, [:rug2], [1])
    $mpmix_ora = $engine.get_mixture_mpset($queries, [:ora2], [1])
    $mpmix = $engine.get_mixture_mpset($queries, $mp_types, $mix_weights)
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx5_rug", o.merge(:template=>:tew, :mps=>$mpmix2, :smoothing=>$sparam_prm ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx5_rug2", o.merge(:template=>:tew, :mps=>$mpmix3, :smoothing=>$sparam_prm ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx5", o.merge(:template=>:tew, :mps=>$mpmix, :smoothing=>$sparam_prm ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:flms=>$rlflms1, :smoothing=>$sparam_prm))
    $i.crt_add_query_set("#{$query_prefix}_PRMSora", o.merge(:template=>:tew, :mps=>$mpmix_ora, :smoothing=>$sparam_prm ))
    
  when 'prms_var'
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o.merge(:smoothing=>$sparam_prm))
    $i.crt_add_query_set("#{$query_prefix}_PRMS_all", o.merge(:smoothing=>$sparam_prm,:mp_all_fields=>true))
    $i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:flms=>$rlflms1, :smoothing=>$sparam_prm))

  
  when 'param_prmd'
    $rsflms = get_rsflms() if !$rsflms
    $mpmix = $engine.get_mixture_mpset($queries, $mp_types, $mix_weights)
    [0.1, 0.3, 0.5, 0.7, 0.85, 0.9, 0.95].each do |lambda|
      $i.crt_add_query_set("#{$query_prefix}_PRMD_l#{lambda}", o.merge(:template=>:prm_ql, :smoothing=>$sparam_prm, :lambda=>lambda))
      $i.crt_add_query_set("#{$query_prefix}_PRMDmx5_l#{lambda}", :template=>:tew_ql,
                              :smoothing=>$sparam_prm, :lambda=>lambda, :mps=>$mpmix)
    end
    
  when 'noise'
    [0.5,1.0,2.0,5.0].each do |mp_noise|
      o = o.dup.merge(:flms=>$rlflms1, :op_comb=>op_comb, :mp_noise=>mp_noise, :mp_all_fields=>true)
      $i.crt_add_query_set("#{$query_prefix}_oPRMS_#{op_comb}_n#{mp_noise}", o)
    end
    
  when 'mp_oracle'
    $i.crt_add_query_set("#{$query_prefix}_PRMSora", o.merge(:flms=>$rlflms1, :smoothing=>$sparam_prm))
    [:wsum].each do |op_comb|
      [0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
        o = o.dup.merge(:flms=>$rlflms1, :op_comb=>op_comb, :mp_unsmooth=>nil, :mp_smooth=>mp_smooth, :mp_all_fields=>true)
        $i.crt_add_query_set("#{$query_prefix}_oPRMS_#{op_comb}_s#{mp_smooth}", o)
      end
      [0.1,0.25,0.5,0.75,1.0].each do |mp_unsmooth|
        o = o.dup.merge(:flms=>$rlflms1, :op_comb=>op_comb, :mp_smooth=>nil, :mp_unsmooth=>mp_unsmooth, :mp_all_fields=>true)
        $i.crt_add_query_set("#{$query_prefix}_oPRMS_#{op_comb}_u#{mp_unsmooth}", o)
      end
    end
    
  
  # Vary Mapping Probabilities
  when 'mp_oracle_topk'
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $i.crt_add_query_set("#{$query_prefix}_PRMSo", o.merge(:flms=>$rlflms1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo1", o.merge(:flms=>$rlflms1, :topk_field=>1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo2", o.merge(:flms=>$rlflms1, :topk_field=>2))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo3", o.merge(:flms=>$rlflms1, :topk_field=>3))

  
  # Getting Baseline Results
  when 'baseline'
    $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>$sparam_prm, :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    $i.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam_prm)
    $i.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam_prm, :lambda=>$prmd_lambda)
  
  # Retrieval parameter sweep
  when 'param_smt'
    #[0.1, 0.3, 0.5, 0.7, 0.8, 0.9, 5,10,25,50,100,250,500,1000].each do |lambda|
    [5,10,25,50,100,250,500,1000].each do |lambda|
      o.merge!(:smoothing=>get_sparam((lambda > 1)? "dirichlet" : "jm", lambda))
      $i.crt_add_query_set("#{$query_prefix}_DQL_l#{lambda}", o.merge(:template=>:ql))
      [:field].each do |op_smt|
        [:wsum].each do |op_comb|
          o.merge!(:op_smt=>op_smt, :op_comb=>op_comb)
          $i.crt_add_query_set("#{$query_prefix}_MFLM_#{op_smt}_#{op_comb}_l#{lambda}" , o.merge(:template=>:hlm, :hlm_weights=>($hlm_weight || [0.1]*($fields.size))))
          $i.crt_add_query_set("#{$query_prefix}_PRM_#{op_smt}_#{op_comb}_l#{lambda}", o.merge(:template=>:prm))    
        end
      end
    end
  
  ################################### Deprecated 
  
  when 'gprms_mix'
    o.merge!(:engine=>:galago, :index_path=>$gindex_path, :smoothing=>'linear', :lambda=>0.1)
    qs = $i.crt_add_query_set("#{$query_prefix}_gDQL" , :smoothing=>$sparam)
    topk = $o[:topk] || 5
    $i.crt_add_query_set("#{$query_prefix}_gPRMS", o)
    
    $rsflms = get_rsflms(qs) if !$rsflms
    $mpmix = $engine.get_mixture_mpset($queries, $mp_types, $mix_weights)
    $i.crt_add_query_set("#{$query_prefix}_gPRMSmx5", o.merge(:template=>:tew, :mps=>$mpmix ))
    $i.crt_add_query_set("#{$query_prefix}_gPRMSrl", o.merge(:flms=>$rlflms1))
  
  # Feature Evaluation
  when 'prms_plus2'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    topk = $o[:topk] || 5
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $rsflms = qs.qrys.map_with_index{|q,i|
      puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
      $engine.get_res_flm q.rs.docs[0..topk]} if $o[:redo] || !$rsflms
    [0.1,0.2,0.4,0.5,0.6,0.8].each do |weight|
      mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug, :cbg], [0.5,0.8,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_rug08_cbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
    end
  
  when 'prms_plus1'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    topk = $o[:topk] || 5
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $rsflms = qs.qrys.map_with_index{|q,i|
      puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
      (q.rs.docs)? $engine.get_res_flm(q.rs.docs[0..topk]) : [] } if $o[:redo] || !$rsflms
    [0.2,0.4,0.5,0.6,0.8].each do |weight|
      mpmix = $engine.get_mixture_mpset($queries, [:cug, :prior], [0.5,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_prior#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
      mpmix = $engine.get_mixture_mpset($queries, [:cug, :cbg], [0.5,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_cbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
      mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug], [0.5,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_rug#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
      mpmix = $engine.get_mixture_mpset($queries, [:cug, :rbg], [0.5,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_rbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
    end
  
  # PRF Parameter Sweep
  when 'prms_prf'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    [3,5,7].each do |topk|
      $rsflms = qs.qrys.map_with_index{|q,i|
        puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
        $engine.get_res_flm q.rs.docs[0..topk]} #if $o[:redo] || !$rsflms
      [0.2,0.4,0.5,0.6,0.8].each do |weight|
        mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug], [0.5,weight])
        $i.crt_add_query_set("#{$query_prefix}_PRMS_top#{topk}_rug#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
      end
    end
  
  # Adding Phrase (OW#1) to PRM-S
  when 'prms_bgram'
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    [0.05, 0.1, 0.15, 0.2].each do |bg_weight|
      $i.crt_add_query_set("#{$query_prefix}_PRMS_bgram_prm#{bg_weight}", o.merge(:template=>:prm, :bgram=>:prm, :bg_weight=>bg_weight ))
      $i.crt_add_query_set("#{$query_prefix}_PRMS_bgram_dm#{bg_weight}", o.merge(:template=>:prm, :bgram=>:dm, :bg_weight=>bg_weight))
    end
  
  when 'mp_noise'
    [0.0,0.5,1.0,2.0,5.0].each do |mp_noise|
      o = o.dup.merge(:flms=>$rlflms1, :mp_noise=>mp_noise, :mp_all_fields=>true)
      $i.crt_add_query_set("#{$query_prefix}_PRM-S_n#{mp_noise}", o)
    end
  # Indri vs. Galago comparison
  when 'engines_dql'
    $o[:lambda] ||= 0.1
    $i.crt_add_query_set("#{$query_prefix}_DQLdir" , :smoothing=>get_sparam('dirichlet',500))
    $i.crt_add_query_set("#{$query_prefix}_gDQLdir" ,:engine=>:galago ,:index_path=>$gindex_path, :smoothing=>'dirichlet',:mu=>500)
    $i.crt_add_query_set("#{$query_prefix}_DQLjm" , :smoothing=>get_sparam('jm',$o[:lambda]))
    $i.crt_add_query_set("#{$query_prefix}_gDQLjm" ,:engine=>:galago ,:index_path=>$gindex_path, :smoothing=>'linear',:lambda=>(1-$o[:lambda]))
  when 'engines_mflm'
    $i.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weights=>([0.1]*($fields.size)))
    $i.crt_add_query_set("#{$query_prefix}_gMFLM" ,:template=>:prm, :smoothing=>'linear', :lambda=>0.5, :hlm_weights=>([0.1]*($fields.size)),:engine=>:galago ,:index_path=>$gindex_path)
    o = $o.dup.merge(:template=>:prm, :smoothing=>get_sparam('jm',0.5))
    $i.crt_add_query_set("#{$query_prefix}_PRM-S", o)
    $i.crt_add_query_set("#{$query_prefix}_gPRM-S" ,:template=>:prm, :smoothing=>'linear', :lambda=>0.5, :engine=>:galago ,:index_path=>$gindex_path)
  end#case
  if $exp == 'perf' || $exp == 'document'
    $i.add_relevant_set($file_qrel)
    $i.fetch_data
  end
rescue DataError
  puts 'Data inconsistency found while loading..'
  exit
end

def process_report
  load to_path('exp_'+$exp+'.rb')
  $i.create_report_index
end

#Run Experiment & Generate Report
info("Experiment '#{$exp}' started..")
if $o[:env]
  load to_path('exp_'+$exp+'.rb')
  $r[:expid] = get_expid_from_env()
  info("RETURN<#{$r.inspect}>RETURN")
else
  process_report()
  #eval IO.read(to_path('exp_'+$exp+'.rb'))
end
info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
