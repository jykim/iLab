#Functions Related to PRM
#
module PRMHelper  
  #Get query for field-level weighting
  # - calculate mapping prob.
  # - transform it appropriately
  def get_prm_query(query, o={})
    #p query
    mps = get_map_prob(query, o.merge(:bgram=>false))
    mps = mps.map{|e|[e[0], e[1].find_all{|e2|e2[1] > o[:mp_thr]}]} if o[:mp_thr]    
    mps = mps.map{|e|[e[0], e[1].to_h.add_noise(o[:mp_noise]).to_a]} if o[:mp_noise]
    mps = mps.map{|e|[e[0], e[1].to_h.smooth(o[:mp_smooth]).to_a]} if o[:mp_smooth]
    mps = mps.map{|e|[e[0], e[1].to_h.unsmooth(o[:mp_unsmooth]).to_a]} if o[:mp_unsmooth]
    #mps.each{|e| info "[get_prm_query] #{e[0]} -> #{e[1].map{|f|[f[0],f[1].r3].join(':')}.join(' ')}"} if o[:verbose]
    if o[:bgram]
      prefix = o[:bg_prefix] || "1"
      bg_weight = o[:bg_weight] || 0.8
      mps_b = get_map_prob(query, o.merge(:flm=>get_col_freq(:bgram=>true)))
      #p mps_b
      result = "#weight(#{1- bg_weight} #combine(\n#{get_tew_query(mps, o)})\n"
      if o[:bgram] == :prm
        qry_bg = get_tew_query(mps_b.map{|e|["##{prefix}(#{e[0]})", e[1]]}, o)
        result += " #{bg_weight} #combine(\n#{qry_bg}) )" if qry_bg.size > 0
      else
        result += " #{bg_weight} #combine(\n#{get_combination(query , prefix)}) )"
      end
      result
    else
      get_tew_query(mps, o)
    end
  end

  #Get Term-wise Element Weighting Query given Mapping Prob.
  # mps = [[qw1, [f1, prob1], [...]], [qw2, ]]
  def get_tew_query(mps, o)
    #debugger
    #info "[get_tew_query] #{mps.inspect}"
    mps_new = mps.map_with_index do |mp,i|
      #p "#{o[:topk_field]}"
      if o[:topk_field]
        mp_topk = mp[1].sort_by{|e|e[1]}.reverse[0..(o[:topk_field]-1)]
        norm = mp_topk.map{|e|e[1]}.sum
        [mp[0], mp_topk.map{|e|[e[0], e[1] / norm]}]
      elsif o[:prior_weight]
        [mp[0], mp[1].map{|e|[ e[0], e[1]*(o[:prior_weight][e[0]] || 1.0) ]}]
      else
        mp
      end
    end#.sort_by{|e|e[1]}.reverse
    mps_new.map{|mp| 
      mp_str = mp[1].map{|e|"#{e[1].r3} #{mp[0]}"+((e[0]!="BoW")? ".(#{e[0]})":"")}.join(' ')
      " #wsum(#{mp_str})" }.join("\n")
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
  #def get_query_from_mp(mp)
  #  "#wsum(#{mp[1].map{|e|"#{e[1]} #{mp[0]}.(#{e[0]})"}.join(" ")}) "
  #end
  #
  ## Phrase-level MP app.
  ## result = [[field1_name,map_prob],[...]]
  #def get_phrase_field_query(query, o={})
  #  o[:phrase_weight] ||= 0.2 
  #  qry_term = get_phrase_field_weight(query , 0).map{|mp| get_query_from_mp(mp)}.join(" ")
  #  qry_phrase = get_phrase_field_weight(query , 1).find_all{|mp|mp[0].scan(/\#/).size>0}.map{|mp| get_query_from_mp(mp)}.join(" ")
  #  s = "#{1-o[:phrase_weight]} #combine(#{qry_term})"
  #  s += "\n#{o[:phrase_weight]} #combine(#{qry_phrase})" if qry_phrase.size > 0
  #  s
  #end
  
end
