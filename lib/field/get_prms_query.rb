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
      mps_b = get_map_prob(query, o.merge(:flm=>get_col_freq(:bgram=>true, :prob=>true)))
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
    #info "[get_tew_query] #{o.inspect}"
    
    op_comb = o[:op_comb] || :wsum
    op_smt = o[:op_smt] || :field
    
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
    
    if o[:engine] == :galago
      mps_new.map{|mp| 
        weight_str = mp[1].map_with_index{|e,i|"#{i}=#{e[1].r3}"}.join(':')
        term_str = mp[1].map{|e| "#{mp[0]}.#{e[0]}"}.join(' ')
        " #combine:#{weight_str}(#{term_str})" }.join("\n")
    else
      mps_new.map{|mp|
        mp_str = mp[1].map{|e|"#{e[1].r3} #{mp[0]}"+((op_smt == :field)? ".(#{e[0]})" : ".#{e[0]}")}.join(' ')
        " ##{op_comb}(#{mp_str})" }.join("\n")
    end
  end
  
  # Run PRM-S query given query & docids
  def debug_prm_query(qno, docids, retmodel, o = {})
    case retmodel
    when :prms
      types, weights = [:cug],[1]
    when :mix
      types, weights = $mp_types, $mix_weights
    end
    
    op_comb = o[:op_comb] || :wsum
    op_smt = o[:op_smt] || :field
    sparam = o[:sparam] || 0.1
    
    qidx = qno - $offset
    mps = get_mixture_mpset([$queries[qidx]], types, weights, :qno=>qidx)[0]
    clm = get_col_freq(:whole_doc=>true,:prob=>true)
    cflm = get_col_freq(:prob=>true)
    
    docids.each do |did|
      score_doc = 0
      dflm = get_doc_field_lm(did, 1)[1]
      mps.each_with_index do |mp,i|
        score_qw = 0
        qw = kstem(mp[0])
        mp[1].each_with_index do |e,j|
          bglm = (op_smt == :field) ? cflm[e[0]] : clm
          ql = (1-sparam) * (dflm[e[0]][qw] || 0.0) + sparam * (bglm[qw] || 1 / (bglm.size * 2.0))
          puts "         #{(ql * e[1]).round_at(6)}\t= #{ql.round_at(6)} * #{e[1].r3} <- #{qw}/#{e[0]}"
          #puts "         #{(slog(ql) * e[1]).round_at(6)}\t= #{slog(ql).round_at(6)} * #{e[1].r3} <- #{qw}/#{e[0]}"
          (op_comb == :weight) ? score_qw += slog(ql) * e[1] : score_qw += ql * e[1]
        end
        puts "#{slog(score_qw).r3}"
        score_doc += ((op_comb == :weight) ? score_qw : slog(score_qw))
      end
      puts "#{(score_doc / mps.size).r3 } <- TotalScore(#{did})\n\n"
    end
  end
  
  def get_hlm_query(query, weights, o = {})
    op_comb = o[:op_comb] || :wsum
    op_smt = o[:op_smt] || :field
    fields = o[:fields] || $fields
    query.split(" ").map{|qw| s = weights.map_with_index{|w,i|"#{w} #{qw}.#{((op_smt == :field)? "(#{fields[i]})" : "#{fields[i]}")}"}.join(" ") ; " ##{op_comb}(#{s})" }.join(" ")
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
