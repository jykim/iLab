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
  o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam)
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
    $i.crt_add_query_set("#{$query_prefix}_PRMSrs#{topk}", o.merge(:flms=>$rsflms))
    $mix_weights = [0.382, 0.382, 0.146] #[0.4, 0.6, 0.25]
    $mpmix = $engine.get_mixture_mpset($queries, $mix_weights)
    $i.crt_add_query_set("#{$query_prefix}_PRMSmx#{topk}_bgram#{lambda}", o.merge(:template=>:tew, :mps=>$mpmix ))
    $i.crt_add_query_set("#{$query_prefix}_PRMSrl", o.merge(:flms=>$rlflms1))
  when 'prms_ora'
    $i.crt_add_query_set("#{$query_prefix}_PRMS", o)
    $i.crt_add_query_set("#{$query_prefix}_PRMSo", o.merge(:flms=>$rlflms1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo1", o.merge(:flms=>$rlflms1, :topk_field=>1))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo2", o.merge(:flms=>$rlflms1, :topk_field=>2))
    $i.crt_add_query_set("#{$query_prefix}_PRMSo3", o.merge(:flms=>$rlflms1, :topk_field=>3))
  when 'mp_noise'
    [0.0,0.5,1.0,2.0,5.0].each do |mp_noise|
      $i.crt_add_query_set("#{$query_prefix}_PRM-S_n#{mp_noise}", :template=>:prm, :smoothing=>$sparam, :mp_noise=>mp_noise)
    end
  when 'mp_smooth'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
      o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam, :mp_smooth=>mp_smooth)
      $i.crt_add_query_set("#{$query_prefix}_PRM-S_s#{mp_smooth}", o)
    end
    
  # Getting Baseline Results
  # - methods that doesn't require parameter tuning
  when 'simple' 
    $i.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    $i.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    $i.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda)

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
