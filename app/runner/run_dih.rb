load 'app/ilab.rb'
load 'app/adhoc/pd_lib.rb'
load 'app/runner/run_dih_helper.rb'

init_env()
init_collection($col)

def $i.run_query( name, query, template, idx, sparam )
  crt_add_query_set(name, :adhoc_topic=>$o[:query], :index_path=>idx, :template=>template, :smoothing=>sparam, :field_doc=>[$field_doc])
end

def $i.crt_add_meta_query_set(name, o = {})
  qs_name = name+"_cw#{o[:col_weight]}_#{o[:norm]}_#{o[:cs_type]}"
  if !fcheck(qs_name+'.qry') || !fcheck(qs_name+'.res')
    $qs = {}
    $qs[$o[:col_type]] = create_query_set(name+"_"+$o[:col_type], o) if $o[:col_type] != 'all'
    ['lists','pdf','html','msword','ppt'].each do |col_type|
      next if col_type == $o[:col_type] && $o[:col_type] != 'all'
      info "Process #{col_type}:"
      set_type_info($o[:pid], col_type)
      if !File.exist?($index_path)
        $engine.build_index("#{$o[:pid]}_#{col_type}" , "#{PD_COL_PATH}/#{$o[:pid]}/#{col_type}_doc" , $index_path , :fields=>$fields, :stopword=>true)
      end
      #info "[crt_add_meta_query_set] index_path = #{$index_path}"
      $qs[col_type] = create_query_set(name.gsub($o[:col_type],col_type), o.merge(:col_type=>col_type,:cs_type=>nil))
    end
    set_type_info($o[:pid], 'all')
    ResultDocumentSet.create_by_merge(qs_name, $qs.values, o)
  end
  crt_add_query_set(qs_name , o)
end

#Choose Retrieval Method
def ILabLoader.build(ilab)
  #['length','length2','length3','pagerank'].each{|e| $engine.run_make_prior(e) }
  case $col
  when 'pd'
    input_test = "crf_test_#{$query_prefix}_#{$remark}.in"
    output_test = "crf_test_#{$query_prefix}_#{$remark}.in.out"
    #model = "crf_model_#{$o[:model_id] || $col_id+'_'+$o[:topic_id]+'_'+$remark}.in"
  end
  # TRAINED PARAMETERS
  # $fields = ['subject','text','to','sent','name','email']
  if $o[:param]
    col_type_old = $col_id
    $col_id = $o[:param]
  end
  set_collection_param($col_id)
  $col_id = col_type_old if $o[:param]
  case $method
  when 'hybrid'
    ilab.crt_add_query_set("#{$query_prefix}_DQL"  , $o.merge(:smoothing=>$sparam))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", $o.merge(:template=>:prm, :smoothing=>$sparam))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S_sem", $o.merge(:template=>:prm, :smoothing=>$sparam, 
      :prm_fields=>$fields[2..-1]))
    ilab.crt_add_query_set("#{$query_prefix}_MFLM_tex", $o.merge(:template=>:hlm, :smoothing=>$sparam, 
      :hlm_fields=>$fields[0..1], :hlm_weights=>$hlm_weight[0..1]))
    [0.1,0.3,0.5,0.7,0.9].each do |lambda|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-H_l#{lambda}", $o.merge(:template=>:prm_h, :smoothing=>$sparam, 
        :prm_fields=>$fields[2..-1], :hlm_fields=>$fields[0..1], :hlm_weights=>$hlm_weight[0..1], :lambda=>lambda))
      ilab.crt_add_query_set("#{$query_prefix}_PRM-H2_l#{lambda}", $o.merge(:template=>:prm, :smoothing=>$sparam, 
        :prm_fields=>$fields[2..-1], :fix_mp_for=>{'title'=>lambda*2, 'content'=>lambda*0.652}))
    end
    
  #------------------ RANK LIST MERGING ---------------#
  #  Single-index Rank-list Merging with Collection Score
  when 'multi_col'
    #Top-score collection for each query
    # Difference for each collection score type
    ilab.crt_add_query_set("#{$query_prefix}_DQL", :smoothing=>$sparam)
    CS_TYPES.each do |cs_type|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_mcs#{cs_type}_#{$o[:cs_smooth]}" , 
        :cs_type=>cs_type, :cs_smooth=>$o[:cs_smooth], :template=>:multi_col, :smoothing=>$sparam)
    end
  # Single-index Rank-list Merging with Weighted MP
  when 'all_cs_type'
    #Top-score collection for each query
    # Difference for each collection score type
    ilab.crt_add_query_set("#{$query_prefix}_DQL", :smoothing=>$sparam)
    CS_TYPES.each do |cs_type|
      #ilab.crt_add_query_set("#{$query_prefix}_DQL_cs#{cs_type}" , :cs_type=>cs_type, :smoothing=>$sparam)
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_cs#{cs_type}" , 
        :cs_type=>cs_type, :template=>:prm, :smoothing=>$sparam)
    end
  # Local retrieval & merge with Collection Score
  when 'meta'
    col_weight = $o[:col_weight] || 0.4
    CS_TYPES.each do |cs_type| #CS_TYPES
      NORM_TYPES.each do |norm_type| 
        #ilab.crt_add_meta_query_set("#{$query_prefix}_DQL_lcs#{cs_type}"  , $o.merge(:smoothing=>$sparam , :cs_type=>cs_type))
        ilab.crt_add_meta_query_set("#{$query_prefix}_PRM-S", 
          $o.merge(:template=>:prm, :smoothing=>$sparam, :norm=>norm_type, :col_weight=>col_weight, :cs_type=>cs_type))
      end
    end

  # Meta-search with different collection weight
  when 'meta_col_weight'
    norm_type, cs_type = :none, :mp_max
    [0.0,0.2,0.4,0.6,0.8,1.0].each do |col_weight|
      ilab.crt_add_meta_query_set("#{$query_prefix}_PRM-S", $o.merge(:col_weight=>col_weight, :cs_type=>cs_type, :norm=>norm_type, :template=>:prm, :smoothing=>$sparam))
    end
  #------------------ CS691 PROJECT  ------------------#
  when 'cut_words'
    [0.0,0.25,0.5,0.75].each_with_thread do |cut_ratio,i|
      ilab.crt_add_query_set("#{$query_prefix}_BM25_crr#{cut_ratio}", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam2($fields , [0.5]*$fields.size), :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :index_path=>"#{$index_path}_#{cut_ratio}_r" , :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      ilab.crt_add_query_set("#{$query_prefix}_BM25F_crr#{cut_ratio}", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam($fields , [0.5]*$fields.size), :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :index_path=>"#{$index_path}_#{cut_ratio}_r", :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      ilab.crt_add_query_set("#{$query_prefix}_MFLM_crr#{cut_ratio}" ,:template=>:hlm ,:smoothing=>['method:jm,lambda:0.1'], :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :index_path=>"#{$index_path}_#{cut_ratio}_r")                            
      ilab.crt_add_query_set("#{$query_prefix}_MFLMF_crr#{cut_ratio}", :template=>:hlm, :smoothing=>['method:raw','node:wsum,method:jm,lambda:0.1'], :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :index_path=>"#{$index_path}_#{cut_ratio}_r", :indri_path=>$indri_path_dih)
    end
  when 'limit_fields'
    (1..$fields.size).to_a.each_with_thread do |no_fields,i|
      $fields = $fields[0..(no_fields-1)]
      ilab.crt_add_query_set("#{$query_prefix}_BM25_uf#{no_fields}", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam2($fields , [0.5]*no_fields), :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      ilab.crt_add_query_set("#{$query_prefix}_BM25F_uf#{no_fields}", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam($fields , [0.5]*no_fields), :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      ilab.crt_add_query_set("#{$query_prefix}_MFLM_uf#{no_fields}" ,:template=>:hlm ,:smoothing=>['method:jm,lambda:0.1'], :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)))                            
      ilab.crt_add_query_set("#{$query_prefix}_MFLMF_uf#{no_fields}", :template=>:hlm, :smoothing=>['method:raw','node:wsum,method:jm,lambda:0.1'], :remote_query=>true, 
                              :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih)
    end
  when 'prmf_verify'
    ilab.crt_add_query_set("#{$query_prefix}_PRM-F_u", :template=>:hlm, :smoothing=>['method:raw','node:wsum,method:jm,lambda:0.1'], 
                            :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih)
    ilab.crt_add_query_set("#{$query_prefix}_DQL", :template=>:ql, :smoothing=>get_sparam('jm','0.1'))
  when 'prmf_smt'
    [0.05,0.1,0.3,0.5,0.7,0.9].each do |lambda|
      ilab.crt_add_query_set("#{$query_prefix}_PRMF_l#{lambda}", :template=>:prm, 
                              :smoothing=>['method:raw',"node:wsum,method:jm,lambda:#{lambda}"], :indri_path=>$indri_path_dih)
    end
    [10,50,100,150,250,500,1000].each do |mu|
      ilab.crt_add_query_set("#{$query_prefix}_PRMF_m#{mu}", :template=>:prm, 
                              :smoothing=>['method:raw',"node:wsum,method:dirichlet,mu:#{mu}"], :indri_path=>$indri_path_dih)
    end
  when 'mp_smooth_all'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_s#{mp_smooth}", :template=>:prm, :smoothing=>$sparam, 
                             :mp_smooth=>mp_smooth)
      ilab.crt_add_query_set("#{$query_prefix}_PRM-F_s#{mp_smooth}", :template=>:prm, :smoothing=>['method:raw','node:wsum,method:dirichlet,mu:50'], 
                             :mp_smooth=>mp_smooth, :indri_path=>$indri_path_dih)
      ilab.crt_add_query_set("#{$query_prefix}_BM25_s#{mp_smooth}",  :template=>:prm, :smoothing=>IndriInterface.get_field_bparam2($fields , $bs),
                             :mp_smooth=>mp_smooth, :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      ilab.crt_add_query_set("#{$query_prefix}_BM25F_s#{mp_smooth}", :template=>:prm, :smoothing=>IndriInterface.get_field_bparam($fields , $bfs), 
                             :mp_smooth=>mp_smooth, :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    end
  when 'bm25f_verify'
    bf = 0
    ilab.crt_add_query_set("#{$query_prefix}_BM25F_u", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam($fields , [bf]*$fields.size), 
                            :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['document']
    ilab.crt_add_query_set("#{$query_prefix}_BM25_d", :template=>:hlm, :smoothing=>IndriInterface.get_field_bparam2($fields , [bf]*$fields.size),
                            :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
  when 'mp_noise'
    [0.0,0.5,1.0,2.0,5.0].each do |mp_noise|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_n#{mp_noise}", :template=>:prm, :smoothing=>$sparam, :mp_noise=>mp_noise)
    end
  when 'mp_smooth'
    [0.0,0.1,0.25,0.5,0.75,1.0].each do |mp_smooth|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S_s#{mp_smooth}", :template=>:prm, :smoothing=>$sparam, :mp_smooth=>mp_smooth)
    end
  when 'mp_smooth2'
    [0.0,0.25,0.5,0.75,1.0].each do |mp_smooth|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-D_s#{mp_smooth}",  :template=>:prm_ql, :smoothing=>$sparam, :mp_smooth=>mp_smooth)
      #ilab.crt_add_query_set("#{$query_prefix}_PRM-D2_s#{mp_smooth}", :template=>:prm_ql, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), :mp_smooth=>mp_smooth)
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S2_s#{mp_smooth}", :template=>:prm,    :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), :mp_smooth=>mp_smooth)
    end
  when 'mp_smt_thr'
    [0.025,0.05,0.1].each do |mp_thr|
      [0.0,0.25,0.5,0.75,1.0].each do |mp_smooth|
        ilab.crt_add_query_set("#{$query_prefix}_PRM-S_s#{mp_smooth}_t#{mp_thr}", :template=>:prm, :smoothing=>$sparam, :mp_smooth=>mp_smooth, :mp_thr=>mp_thr)
      end
    end
  #------------------ DIH Project ------------------#
  when 'simple' #methods that doesn't require parameter tuning
    #ilab.crt_add_query_set("#{$query_prefix}_BM25F", :template=>:hlm, :smoothing=>$bm25f_smt, 
    #                        :hlm_weights=>($bm25f_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_DQL" ,:smoothing=>$sparam)
    #ilab.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), 
    #                        :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda)
    #ilab.crt_add_query_set("#{$query_prefix}_MFLM_u" ,:template=>:hlm ,:smoothing=>$sparam, 
    #                        :hlm_weights=>([0.1]*($fields.size)))
  when 'baseline'
    $bm25f_smt = IndriInterface.get_field_bparam($fields , $bfs, $k1)
    $bm25_smt = IndriInterface.get_field_bparam2($fields , $bs, $k1)
    #BASELINE
    ilab.crt_add_query_set("#{$query_prefix}_DQL" ,:smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_MFLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.5), 
                            :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    #ilab.crt_add_query_set("PRM", :template=>:prm, :smoothing=>get_sparam('jm',0.5))
    ilab.crt_add_query_set("#{$query_prefix}_BM25", :template=>:hlm, :smoothing=>$bm25_smt, 
                            :hlm_weights=>($bm25_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_BM25F", :template=>:hlm, :smoothing=>$bm25f_smt, 
                            :hlm_weights=>($bm25f_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    #ilab.crt_add_query_set("#{$query_prefix}_PRMf", :template=>:prm, :smoothing=>['method:raw',"node:wsum,method:dirichlet,mu:50"], :indri_path=>$indri_path_dih)

    #IMPROVED (order by TREC Performance)
    #ilab.crt_add_query_set("#{$query_prefix}_PRM-Fd50", :template=>:prm, :smoothing=>['method:raw','node:wsum,method:dirichlet,mu:50'], :indri_path=>$indri_path_dih)
    #ilab.crt_add_query_set("#{$query_prefix}_PRM-Fj005", :template=>:prm, :smoothing=>['method:raw','node:wsum,method:jm,lambda:0.05'], :indri_path=>$indri_path_dih)
    #ilab.crt_add_query_set("#{$query_prefix}_PRM-B", :template=>:prm, :smoothing=>$bm25f_smt, 
    #                        :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    #ilab.crt_add_query_set("#{$query_prefix}_MFLMF", :template=>:hlm, :smoothing=>['method:raw','node:wsum,method:dirichlet,mu:50'], :indri_path=>$indri_path_dih, 
    #                        :hlm_weights=>($mflmf_weight || [0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_MFLM2" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), 
                            :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D2", :template=>:prm_ql, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), :lambda=>$prmd_lambda)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S2", :template=>:prm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu))
  when 'document'
    ilab.crt_add_query_set("#{$query_prefix}_BM25F", :template=>:hlm, :smoothing=>$bm25f_smt, 
                            :hlm_weights=>($bm25f_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S2", :template=>:prm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D2", :template=>:prm_ql, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), :lambda=>$prmd_lambda)
    ilab.crt_add_query_set("#{$query_prefix}_MFLM2" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu), 
                            :hlm_weights=>($hlm_weight || [0.1]*($fields.size)))
  when 'length'
    ilab.crt_add_query_set("#{$query_prefix}_BM25F", :template=>:hlm, :smoothing=>$bm25f_smt, 
                            :hlm_weights=>($bm25f_weight || [0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_DQL" ,:smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S", :template=>:prm, :smoothing=>$sparam)
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda)    
    #ilab.crt_add_query_set("#{$query_prefix}_PRM-S2", :template=>:prm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , $mu))    
  when 'indri_old' #experiment using Indri 2.5 -- no difference
    ilab.crt_add_query_set("#{$query_prefix}_DQL_o" ,:smoothing=>$sparam, :indri_path=>$indri_path_old, :index_path=>($index_path+'_old'))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-S_o", :template=>:prm, :smoothing=>$sparam, :indri_path=>$indri_path_old, :index_path=>($index_path+'_old'))
    ilab.crt_add_query_set("#{$query_prefix}_PRM-D_o", :template=>:prm_ql ,:smoothing=>$sparam, :lambda=>$prmd_lambda, :indri_path=>$indri_path_old, :index_path=>($index_path+'_old'))    
  when 'prior'
    [:ql,:prm].each do |retr|
      [nil,"length","pagerank"].each do |pl| #,"length2","length3"
        [0.1].each do |ld| #,0.3,0.5,0.7,0.9
          ilab.crt_add_query_set("#{$col_id}#{$o[:topic_id]}_#{retr}_ld#{ld}_pl#{pl}" , :smoothing=>[get_sparam('jm',ld)] , :template=>retr, :prior=>pl )
        end
      end
    end
  when 'topk' #How many TopK field to include in calc.
    [1,2,3,5].each do |n|
      ilab.crt_add_query_set("#{$query_prefix}_PRM_T#{n}", :template=>:prm, :smoothing=>get_sparam('jm',0.5))
      #ilab.crt_add_query_set("#{$query_prefix}_#{$o[:model_id]}_CPRM_T#{n}", :template=>:tew, :smoothing=>get_sparam('jm',0.5),:mps=>result_crf[1], \
      #                        :redo=>true, :topk_field=>n)
    end
  when 'smt_jm'
    [0,0.1, 0.3, 0.5, 0.7, 0.85, 0.9, 0.95].each do |lambda|
      #ilab.crt_add_query_set("#{$query_prefix}_DQL_l#{lambda}" ,:smoothing=>get_sparam('jm',lambda))
      #ilab.crt_add_query_set("#{$query_prefix}_PRM_l#{lambda}", :template=>:prm, :smoothing=>get_sparam('jm',lambda))    
      ilab.crt_add_query_set("#{$query_prefix}_PRMf_l#{lambda}", :template=>:prm, :smoothing=>['method:raw',"node:wsum,method:jm,lambda:#{lambda}"], :indri_path=>$indri_path_dih)
    end
  when 'smt_dir'
    [5,10,50,100,250,500,1500,2500].each do |mu|
      #ilab.crt_add_query_set("#{$query_prefix}_DQL_mu#{mu}" ,:smoothing=>get_sparam('dirichlet',mu))
      #ilab.crt_add_query_set("#{$query_prefix}_PRM_mu#{mu}", :template=>:prm, :smoothing=>get_sparam('dirichlet',mu))
      ilab.crt_add_query_set("#{$query_prefix}_PRMf_mu#{mu}", :template=>:prm, :smoothing=>['method:raw',"node:wsum,method:dirichlet,mu:#{mu}"], :indri_path=>$indri_path_dih)
    end
  when 'smt_dir_le'
    [50,100,150,250,500].each do |mu|
      ilab.crt_add_query_set("#{$query_prefix}_PRM-S2_mu#{mu}" , :template=>:prm, :smoothing=>IndriInterface.get_field_sparam($fields , $mus , mu))
    end
  when 'smt_test_jm'
    ilab.crt_add_query_set("#{$query_prefix}_DQL"     ,:smoothing=>get_sparam('jm',0.1))
    ilab.crt_add_query_set("#{$query_prefix}_FLM"     ,:template=>:hlm, :smoothing=>get_sparam('jm',0.1), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_2S"  ,:template=>:hlm, :smoothing=>get_sparam2('jm',{:lambda=>0.1,:documentLambda=>0.1}), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_FS1" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields,[0.1,0.1,0.1,0.1,0.1] ,0.1,'jm'), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_FS2" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields,[0.3,0.1,0.5,0.5,0.5] ,0.1,'jm'), :hlm_weights=>([0.1]*($fields.size)))
  when 'smt_test_dir'
    ilab.crt_add_query_set("#{$query_prefix}_DQL"     ,:smoothing=>get_sparam('dir',250))
    ilab.crt_add_query_set("#{$query_prefix}_FLM"     ,:template=>:hlm, :smoothing=>get_sparam('dir',250), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_2S"  ,:template=>:hlm, :smoothing=>get_sparam2('dir',{:lambda=>250,:documentLambda=>100}), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_FS1" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields,[100,100,100,100,100] ,250,'dir'), :hlm_weights=>([0.1]*($fields.size)))
    ilab.crt_add_query_set("#{$query_prefix}_FLM_FS2" ,:template=>:hlm, :smoothing=>IndriInterface.get_field_sparam($fields,[200,50,200,200,200] ,250,'dir'), :hlm_weights=>([0.1]*($fields.size)))
  when 'bm25f'
    #['subject','text','to','sent','name','email']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f5_st", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>[1,1,0,0,0,0], :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")    
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f5_st2", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>[1,1,0.001,0.001,0.001,0.001], :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")    
    #$fields = ['subject','text','name']
    #ilab.crt_add_query_set("#{$query_prefix}_BM25f_f3", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
    #                        :hlm_weights=>([1.0]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['subject','text']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f2_st", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>([1.0]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['subject','text']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f1_s", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>[0.0,1.0], :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['subject','text','name']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f1_s2", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>[0.0,1.0,0.0], :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['subject','text','name']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_f1_s3", :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>[0.0001,1.0,0.0001], :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    $fields = ['document']
    ilab.crt_add_query_set("#{$query_prefix}_BM25f_doc" , :template=>:hlm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
                            :hlm_weights=>([0.1]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
    ilab.crt_add_query_set("#{$query_prefix}_DQL"      ,:smoothing=>get_sparam('jm',0.1))
    #ilab.crt_add_query_set("#{$query_prefix}_BM25f_prm"  , :template=>:prm, :smoothing=>["method:bf1,bf:0.5","node:wsum,method:bf2,k1:1.0"], 
    #                        :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
  when 'bm25f_param'
    $fields = ['document']
    [0.1, 0.3, 0.5, 0.7, 0.9].each_with_index do |bf,i|
      [0.1, 0.3, 0.5, 0.7, 0.9].each_with_index do |k,j|
        ilab.crt_add_query_set("#{$query_prefix}_BM25f_doc_bf#{i}_k#{j}", :template=>:hlm, :smoothing=>["method:bf1,bf:#{bf}","node:wsum,method:bf2,k1:#{k}"], 
                                :hlm_weights=>([1.0]*($fields.size)), :indri_path=>$indri_path_dih, :param_query=>"-msg_path='#{$bm25f_path}'")
      end
    end
  when 'prmf_test'
    ilab.crt_add_query_set("#{$query_prefix}_DQL_nosmt"  , :smoothing=>get_sparam('jm',0))
    ilab.crt_add_query_set("#{$query_prefix}_PRMQL_0.7", :template=>:prm_ql ,:smoothing=>get_sparam('jm',0), :lambda=>0.7)
    ilab.crt_add_query_set("#{$query_prefix}_PRM_nosmt"  , :template=>:prm, :smoothing=>['method:raw',"node:wsum,method:jm,lambda:0"], :indri_path=>$indri_path_dih)
    ilab.crt_add_query_set("#{$query_prefix}_PRM_nosmt_o", :template=>:prm ,:smoothing=>get_sparam('jm',0))
  when 'hlm_test'
    ilab.crt_add_query_set("#{$query_prefix}_DQL" ,:smoothing=>get_sparam('jm',0.1))
    ilab.crt_add_query_set("#{$query_prefix}_HLM" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.1), :hlm_weights=>[0,0,1,0,0,0])
    ilab.crt_add_query_set("#{$query_prefix}_HLM2" ,:template=>:hlm, :smoothing=>get_sparam('jm',0.1), :hlm_weights=>[0.1,0.1,0.5,0.1,0.1,0.1])
    ilab.crt_add_query_set("#{$query_prefix}_PRM", :template=>:prm, :smoothing=>get_sparam('jm',0.1))
  # Heuristically manipulate MP -> didn't work
  when 'hprm'
    [0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8].each do |topf_low|
      [0.85,0.9,0.95,1.0].each do |topf_hi|
        ilab.crt_add_query_set("#{$query_prefix}_HPRM-#{topf_low}-#{topf_hi}", 
          :template=>:hprm ,:smoothing=>get_sparam('jm',0.5), :topf_low=>topf_low,:topf_hi=>topf_hi)
      end
    end
  when 'prmql'
    [0.1, 0.3, 0.5, 0.7, 0.85, 0.9, 0.95].each do |lambda|
      ilab.crt_add_query_set("#{$query_prefix}_PRMQL_#{lambda}", :template=>:prm_ql ,
                              :smoothing=>get_sparam('jm',0.1), :lambda=>lambda)
    end
  when 'cval_crf'
    ilab.crt_add_query_set("#{$o[:env]}#{$query_prefix}_DQL" ,:smoothing=>get_sparam('jm',0.1), :prior=>'length')
    ilab.crt_add_query_set("#{$o[:env]}#{$query_prefix}_PRM", :template=>:prm, :smoothing=>get_sparam('jm',0.1), :prior=>'length')
    #ilab.add_query_set run_cprm_query(input_test, model, $o.merge(:skip_test=>true))
  when 'dprm_test'
    ilab.crt_add_query_set("#{$query_prefix}_DQL_t" ,:smoothing=>get_sparam('jm',0.1))
    ilab.crt_add_query_set("#{$col_id}_dprm", :template=>:dprm_test, :smoothing=>get_sparam('jm',0.1))
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

#Run Experiment & Generate Report
info("Experiment '#{$exp}' started..")
if $o[:env]
  load to_path('exp_'+$exp+'.rb')
  $r[:expid] = get_expid_from_env()
  info("RETURN<#{$r.inspect}>RETURN")
else
  eval IO.read(to_path('exp_'+$exp+'.rb'))
  $i.create_report_index
end
info("Sending report to belmont...")
`ssh jykim@belmont 'source ~/.bash_profile;/usr/dan/users4/jykim/dev/rails/lifidea/script/sync_rpt.rb dih #{$col}'`
info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
