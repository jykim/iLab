#Functions Related to PRM
#
module PRMHelper
  MP_MIN = 0.0001
  # Get Mapping Prob. for given query
  # result = [[qw1,[[f1,mp1],[f2,mp2]]], [qw2,...]]
  def get_map_prob(query, o={})
    return query if query.scan(/\(/).size > 0
    mps = [] ; col_scores = {}
    fields = o[:prm_fields] || $fields
    flm = o[:flm] || get_col_freq((o[:df]) ? {:df=>true} : {}).map_hash{|k,v|[k,v.to_p]}
    #puts "[get_map_prob] flm = #{o[:flm]}" if o[:flm]
    query.split(" ").each_with_index do |qw,i|
      #Read Collection Stat.
      qw_s = case (o[:stemmer] || $stemmer)
      when 'krovetz' : kstem(qw)
      when 'porter' : pstem(qw)
      else
        qw.downcase
      end
      weights = flm.map_hash{|k,v|[k,v[qw_s]] if v[qw_s] && fields.include?(k)}
      mp = weights.map_hash{|e|v=e[1]/weights.values.sum ; [e[0],((v >= MP_MIN)? v : MP_MIN)]}
      if mp.size == 0
        error "[get_map_prob] Query-term [#{qw}->#{qw_s}] not found!"
      elsif o[:mp_all_fields]
        mp = fields.map_hash{|f|[f, ((mp[f])? mp[f] : MP_MIN )]}
      end
      #o[:fix_mp_for].map{|k,v|mp[k] = v} if o[:fix_mp_for]
      mps[i] = [qw, mp.find_all{|e|e[1]>0}.to_a.sort_val]
    end
    mps.find_all{|mp|mp[1].size>0}
  end
  
  def get_mixture_mp(query, weights, o = {})
    raw = []
    raw << get_map_prob(query) << get_map_prob(query, :df=>true)
  end
  
  # Get the KL-divrgence between two MP sets
  # 
  def get_mpset_klds( mpset1, mpset2  )
    return error "Length not equal!" if mpset1.size != mpset2.size
    mpset1.map_with_index{|mps,i| mps.map{|k,v|v.kld(mpset2[i][k])}.sum}
  end
  
  # Get MPs estimated from collection FLMs
  def get_mpset( query_set, o = {} )
    query_set.map{|q| get_map_prob(q, o).map_hash{|e|[e[0], e[1].to_h]}}
  end
  
  # Get MPs estimated from a set of FLMs
  def get_mpset_from_flms( queries, flms, o = {} )
    flms.map_with_index{|e,i|get_map_prob(queries[i], o.merge(:flm=>e)).map_hash{|e2|[e2[0], e2[1].to_h]}}
  end
  
  #Get query for field-level weighting
  # - calculate mapping prob.
  # - transform it appropriately
  def get_prm_query(query, o={})
    mps = get_map_prob(query, o)
    mps = mps.map{|e|[e[0], e[1].find_all{|e2|e2[1] > o[:mp_thr]}]} if o[:mp_thr]    
    mps = mps.map{|e|[e[0], e[1].to_h.add_noise(o[:mp_noise]).to_a]} if o[:mp_noise]
    mps = mps.map{|e|[e[0], e[1].to_h.smooth(o[:mp_smooth]).to_a]} if o[:mp_smooth]
    #mps.each{|e| info "[get_prm_query] #{e[0]} -> #{e[1].map{|f|[f[0],f[1].r3].join(':')}.join(' ')}"} if o[:verbose]
    return get_tew_query(mps, o)
  end

  #Get Term-wise Element Weighting Query given Mapping Prob.
  def get_tew_query(mps, o)
    #debugger
    #info "[get_tew_query] #{mps.inspect}"
    mps_new = mps.map_with_index do |mp,i|
      #p "#{o[:topk_field]}"
      if o[:topk_field]
        mp_topk = mp[1].sort_by{|e|e[1]}.reverse[0..(o[:topk_field]-1)]
        norm = mp_topk.map{|e|e[1]}.sum
        [mp[0], mp_topk]
      elsif o[:prior_weight]
        [mp[0], mp[1].map{|e|[ e[0], e[1]*(o[:prior_weight][e[0]] || 1.0) ]}]
      else
        mp
      end
    end#.sort_by{|e|e[1]}.reverse
    mps_new.map{|mp| " #wsum(#{mp[1].map{|e|"#{e[1].r3} #{mp[0]}"+((e[0]!="BoW")? ".(#{e[0]})":"")}.join(' ')})" }.join("\n")
    #mps_new.map{|mp| " #wsum(#{mp[1].sort_by{|e|e[1]}.reverse.map{|e|"#{e[1].r3} #{mp[0]}.(#{e[0]})"}.join(' ')})" }.join("\n")
  end
  
  def get_hlm_query(query, weights, fields = nil)
    fields ||= $fields
    query.split(" ").map{|qw| s = weights.map_with_index{|w,i|"#{w} #{qw}.(#{fields[i]})"}.join(" ") ; " #wsum(#{s})" }.join(" ")
  end
  
  def get_hlm_gquery(query, weights, fields = nil)
    fields ||= $fields
    query.split(" ").map{|qw| 
      s = weights.map_with_index{|w,i|"#{qw}.#{fields[i]}"}.join(" ")
      " #combine(#{s})" 
    }.join(" ")
  end
  
  def get_prm_gquery(query, weights = nil, fields = nil)
    fields ||= $fields
    if weights
      param_weights = ":weights=#{weights.join(",")}"
    end
    " #prms:fields=#{fields.join(",")}#{param_weights}(#{query})" 
  end
  
  
  ##### DEPRECATED #####

  #Get query expression for single query-term
  #mp = [query_term, [[field_1,weight_1], ...]]
  def get_query_from_mp(mp)
    "#wsum(#{mp[1].map{|e|"#{e[1]} #{mp[0]}.(#{e[0]})"}.join(" ")}) "
  end
  
  def get_phrase_field_weight(query, phrase_flag = 0)
    index_path = case $col
                 when 'imdb' : '/work1/xuexb/DBProject/index_plot'
                 when 'monster' : '/work1/xuexb/DBProject/index_monster'
                 end
    out_filepath = to_path("phrase_#{phrase_flag}_p#{File.basename(index_path)}_#{query.gsub(/ /,"-")}.tmp")
    if !fcheck(out_filepath) || $o[:redo]
      cmd = fwrite('cmd_get_phrase_field_weight.log' , " /work1/xuexb/DBProject/app/PhraseMappingProb #{index_path} #{out_filepath} #{phrase_flag} 10 #{query}" , :mode=>'a') ; `#{cmd}`
    end
    result = IO.read(out_filepath)
    info "[get_phrase_field_query] error for #{query}" if result.scan(/\|/).size == 0
    result.split("\n").map do |e| 
      mp_word = e.split("|")[0]
      mp_vector = e.split("|")[1].split(" ").map_hash{|e|e.split(":")}.map{|k,v|[k,(v.scan(/e/i).size>0)? 0.0001 : v.to_f]}.find_all{|e|e[1] > 0}.sort_by{|e|e[1]}.reverse
      [mp_word, mp_vector]
    end
  end
  
  # Phrase-level MP app.
  # result = [[field1_name,map_prob],[...]]
  def get_phrase_field_query(query, o={})
    o[:phrase_weight] ||= 0.2 
    qry_term = get_phrase_field_weight(query , 0).map{|mp| get_query_from_mp(mp)}.join(" ")
    qry_phrase = get_phrase_field_weight(query , 1).find_all{|mp|mp[0].scan(/\#/).size>0}.map{|mp| get_query_from_mp(mp)}.join(" ")
    s = "#{1-o[:phrase_weight]} #combine(#{qry_term})"
    s += "\n#{o[:phrase_weight]} #combine(#{qry_phrase})" if qry_phrase.size > 0
    s
  end
  
  #recover stemmed 'word' from 'source'
  #def unstem(word, source)
  #  source.scan(/\b#{word}/i).each do |w|
  #    return w if kstem(w) == word
  #  end
  #end
  
  #PRM with DQL
  #def get_prm_ql2_query(query, o={})
  #  mps = get_map_prob(query, o)
  #  lambdas = [o[:lambda]] * mps.size
  #  mps.map_with_index do |mp,i|
  #    "#wsum(#{1-lambdas[i]} #{get_tew_query([mp], o)} #{lambdas[i]} #{mp[0]})"
  #  end
  #end
  
  
end
