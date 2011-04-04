load 'app/ilab.rb'
load 'app/adhoc/pd_lib.rb'
load 'app/runner/run_prms_helper.rb'

init_env()
init_collection($col)
set_collection_param($col_id)

#Choose Retrieval Method
def ILabLoader.build(ilab)
  puts "METHOD : #$method"
  case $method
    
  # Getting Optimal MP results
  when 'prms_ora'
    o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    #ilab.crt_add_query_set("#{$query_prefix}_PRMSall", o.merge(:mp_all_fields=>true))
    ilab.crt_add_query_set("#{$query_prefix}_PRMS", o)
    ilab.crt_add_query_set("#{$query_prefix}_PRMSo", o.merge(:oracle=>true))
    ilab.crt_add_query_set("#{$query_prefix}_PRMSo1", o.merge(:oracle=>true, :topk_field=>1))
    ilab.crt_add_query_set("#{$query_prefix}_PRMSo2", o.merge(:oracle=>true, :topk_field=>2))
    ilab.crt_add_query_set("#{$query_prefix}_PRMSo3", o.merge(:oracle=>true, :topk_field=>3))
  when 'mp_noise'
    [0.0,0.5,1.0,2.0,5.0].each do |mp_noise|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_n#{mp_noise}", :template=>:prm, :smoothing=>$sparam, :mp_noise=>mp_noise)
    end
  when 'mp_smooth'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
      o = $o.dup.merge(:template=>:prm, :smoothing=>$sparam, :mp_smooth=>mp_smooth)
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_s#{mp_smooth}", o)
    end
    
  # Getting Baseline Results
  # - methods that doesn't require parameter tuning
  when 'simple' 
    ilab.crt_add_query_set("#{$query_prefix}_DQL" , :smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda)

  # Indri vs. Galago comparison
  when 'engines_dql'
    $o[:lambda] ||= 0.1
    ilab.crt_add_query_set("#{$query_prefix}_DQLdir" , :smoothing=>get_sparam('dirichlet',500))
    ilab.crt_add_query_set("#{$query_prefix}_gDQLdir" ,:engine=>:galago ,:index_path=>$gindex_path, :smoothing=>'dirichlet',:mu=>500)
    ilab.crt_add_query_set("#{$query_prefix}_DQLjm" , :smoothing=>get_sparam('jm',$o[:lambda]))
    ilab.crt_add_query_set("#{$query_prefix}_gDQLjm" ,:engine=>:galago ,:index_path=>$gindex_path, :smoothing=>'linear',:lambda=>(1-$o[:lambda]))
  when 'engines_mflm'
    ilab.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_gMFLM" ,:template=>:prm, :smoothing=>'linear', :lambda=>0.5, :hlm_weights=>([0.1]*($fields.size)),:engine=>:galago ,:index_path=>$gindex_path)
    o = $o.dup.merge(:template=>:prm, :smoothing=>get_sparam('jm',0.5))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", o)
    ilab.crt_add_query_set("#{$query_prefix}_gPRM-S" ,:template=>:prm, :smoothing=>'linear', :lambda=>0.5, :engine=>:galago ,:index_path=>$gindex_path)
  end#case
  if !ilab.fcheck($file_qrel)
    warn "Create Qrel First!"
    $exp = 'qrel'
    return
  end
  ilab.add_relevant_set($file_qrel)
  ilab.fetch_data
end

begin
  $i = ILabLoader.load($i) if $exp != 'qrel' 
rescue DataError
  puts 'Data inconsistency found while loading..'
  exit
end

def process_report
  load to_path('exp_'+$exp+'.rb')
  $i.create_report_index
  #info("Sending report to belmont...")
  #`ssh jykim@belmont 'source ~/.bash_profile;/usr/dan/users4/jykim/dev/rails/lifidea/script/sync_rpt.rb dih #{$col}'`
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
