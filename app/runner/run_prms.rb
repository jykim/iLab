load 'app/ilab.rb'
load 'app/adhoc/pd_lib.rb'
load 'app/runner/run_prms_helper.rb'

init_env()
init_collection($col)
set_collection_param($col_id)

#Choose Retrieval Method
#def ILabLoader.build(ilab)
begin
  puts "METHOD : #$method"
  o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam_prm)
  case $method
  # Getting Optimal MP results
  when 'prms'
    $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    #$i.crt_add_query_set("#{$query_prefix}_PRMSdf", o.merge(:df=>true))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo", o.merge(:flms=>$rlflms1))
    
  when 'prms_mix'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    topk = $o[:topk] || 5
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    
    $rsflms = qs.qrys.map_with_index{|q,i|
      puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
      $engine.get_res_flm q.rs.docs[0..topk]} if $o[:redo] || !$rsflms
    $i.crt_add_query_set("#{$query_prefix}_PRMSrs", o.merge(:flms=>$rsflms.map{|e|e[1]}))

    $types, $weights = [:cug, :rug], [1.0, 0.4]	
    $mpmix = $engine.get_mixture_mpset($queries, $types, $weights)
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx", o.merge(:template=>:tew, :mps=>$mpmix ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:flms=>$rlflms1))
  
  # Feature Evaluation
  when 'prms_plus2'
    qs = $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    topk = $o[:topk] || 5
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $rsflms = qs.qrys.map_with_index{|q,i|
      puts "[get_res_flm] #{i}th query processed" if i % 20 == 1      
      $engine.get_res_flm q.rs.docs[0..topk]} if $o[:redo] || !$rsflms
    [0.1,0.2,0.4,0.5,0.6,0.8].each do |weight|
    #  mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug, :cbg], [0.5,0.8,weight])
    #  $i.crt_add_query_set("#{$query_prefix}_PRMS_rug08_cbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
    
    mpmix = $engine.get_mixture_mpset($queries, [:cug, :rbg], [0.5,weight])
    $i.crt_add_query_set("#{$query_prefix}_PRMS_rbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))

      mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug, :rbg], [0.5,0.8,weight])
      $i.crt_add_query_set("#{$query_prefix}_PRMS_rug08_rbg#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))


    #  mpmix = $engine.get_mixture_mpset($queries, [:cug, :rug, :prior], [0.5,0.8,weight])
    #  $i.crt_add_query_set("#{$query_prefix}_PRMS_rug08_prior#{weight}", o.merge(:template=>:tew, :mps=>mpmix ))
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
    
  # Vary Mapping Probabilities
  when 'prmso_topk'
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $i.crt_add_query_set("#{$query_prefix}_PRMSo", o.merge(:flms=>$rlflms1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo1", o.merge(:flms=>$rlflms1, :topk_field=>1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo2", o.merge(:flms=>$rlflms1, :topk_field=>2))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo3", o.merge(:flms=>$rlflms1, :topk_field=>3))
  when 'mp_noise'
    [0.0,0.5,1.0,2.0,5.0].each do |mp_noise|
      o = o.dup.merge(:flms=>$rlflms1, :mp_noise=>mp_noise, :mp_all_fields=>true)
      $i.crt_add_query_set("#{$query_prefix}_PRM-S_n#{mp_noise}", o)
    end
  when 'mp_smooth'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
      o = o.dup.merge(:flms=>$rlflms1, :mp_smooth=>mp_smooth, :mp_all_fields=>true)
      $i.crt_add_query_set("#{$query_prefix}_oPRM-S_s#{mp_smooth}", o)
    end
  when 'mp_unsmooth'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_unsmooth|
      o = o.dup.merge(:flms=>$rlflms1, :mp_unsmooth=>mp_unsmooth, :mp_all_fields=>true)
      $i.crt_add_query_set("#{$query_prefix}_oPRM-S_u#{mp_unsmooth}", o)
    end
    
  # Getting Baseline Results
  when 'simple' 
    $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>$sparam_prm, :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    $i.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam_prm)
    $i.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam_prm, :lambda=>$prmd_lambda)
  
  # Smoothing parameter sweep
  when 'param_jm'
    [0,0.1, 0.3, 0.5, 0.7, 0.8, 0.9].each do |lambda|
      $i.crt_add_query_set("#{$query_prefix}_DQL_l#{lambda}" ,:smoothing=>get_sparam('jm',lambda))
      $i.crt_add_query_set("#{$query_prefix}_PRM_l#{lambda}", :template=>:prm, :smoothing=>get_sparam('jm',lambda))    
    end
  when 'param_dir'
    [5,10,50,100,250,500,1500,2500].each do |mu|
      $i.crt_add_query_set("#{$query_prefix}_DQL_mu#{mu}" ,:smoothing=>get_sparam('dirichlet',mu))
      $i.crt_add_query_set("#{$query_prefix}_PRM_mu#{mu}", :template=>:prm, :smoothing=>get_sparam('dirichlet',mu))
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
  if $exp == 'perf'
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
