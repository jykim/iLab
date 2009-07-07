#Functions Related to PRM
#
module PRMHelper

  def get_clm_by_col()
    @clm ||= get_col_freq().group_by{|k,v|k.split("_")[0]}.map_hash{|k,v|[k, v.to_h.merge_elements.to_p]}
  end
  
  # Normalize and weight mapping probability for each collection
  # mp = {f1=>mp1, f2=>mp2, ...}
  # col_scores = {col1=>score1, }
  def scale_map_prob(qw, mp, cs_type = :uniform)
    mp_group = mp.group_by{|k,v|k.split("_")[0]}
    col_scores = COL_TYPES.map_hash { |col|
      #debugger
      unless mp_group[col]
        [col,0.0]
      else
        case cs_type
        when :uniform
          [col, 1.0]
        when :mp_max
          [col, mp_group[col].max{|a,b|a[1]<=>b[1]}[1]]
        when :mp_mean
          [col, mp_group[col].map{|e|e[1]}.mean]
        when :cql
          [col, get_clm_by_col()[col][qw]]
        end
      end
    }.to_p.smooth(0.1)
    debug "[scale_map_prob] #{qw} : #{col_scores.r2.sort_val.inspect}"
    #debugger
    [col_scores, mp_group.map{|col,fields|fields.to_p(col_scores[col]).sort_val}.collapse]
  end
  
  # Get Mapping Prob. for given query
  # result = [[qw1,[[f1,mp1],[f2,mp2]]], [qw2,...]]
  def get_map_prob(query, o={})
    return query if query.scan(/\(/).size > 0
    mps = [] ; col_scores = {}
    query.split(" ").each_with_index do |qw,i|
      #Read Collection Stat.
      qw_s = kstem(qw.downcase)
      weights = get_col_freq(:prob=>true).map_hash{|k,v|[k,v[qw_s]] if v[qw_s] && $fields.include?(k)}
      if o[:cs_type]
        mps[i] = [qw]
        col_scores[qw_s], mps[i][1] = *scale_map_prob(qw_s, weights, o[:cs_type])
        #debugger
      else
        mp = weights.map_hash{|e|v=e[1]/weights.values.sum ; [e[0],((v >= 0.0001)? v : 0.0)]}
        mp = $fields.map_hash{|f|[f, ((mp[f])? mp[f] : 0.0001)]} if o[:mp_all_fields]
        mps[i] = [qw, mp.find_all{|e|e[1]>0}.sort_val]
      end
    end
    cs_scores_all =  col_scores.merge_by_product.to_p.r2.sort_val
    $top_cols ||= {} 
    $top_cols[query] ||= {}
    $top_cols[query][o[:cs_type]] = cs_scores_all[0]
    info "[get_map_prob] #{query} : #{cs_scores_all.inspect}"    
    mps.find_all{|mp|mp[1].size>0}
  end
  
  #recover stemmed 'word' from 'source'
  def unstem(word, source)
    source.scan(/\b#{word}/i).each do |w|
      return w if kstem(w) == word
    end
  end
  
  #PRM with DQL
  def get_prm_ql2_query(query, o={})
    mps = get_map_prob(query, o)
    lambdas = [o[:lambda]] * mps.size
    mps.map_with_index do |mp,i|
      "#wsum(#{1-lambdas[i]} #{get_tew_query([mp], o)} #{lambdas[i]} #{mp[0]})"
    end
  end
      
  #Get query for field-level weighting
  def get_prm_query(query, o={})
    mps = get_map_prob(query, o)
    mps = mps.map{|e|[e[0], e[1].find_all{|e2|e2[1] > o[:mp_thr]}]} if o[:mp_thr]    
    mps = mps.map{|e|[e[0], e[1].to_h.add_noise(o[:mp_noise]).to_a]} if o[:mp_noise]
    mps = mps.map{|e|[e[0], e[1].to_h.smooth(o[:mp_smooth]).to_a]} if o[:mp_smooth]
    mps.each{|e| info "[get_prm_query] #{e[0]} -> #{e[1].map{|f|[f[0],f[1].r3].join(':')}.join(' ')}"} if o[:verbose]
    return get_tew_query(mps, o)
    
    #return "1 #combine(#{result})" if query.split(" ").size < 2
    #
    ##Phrase Detection
    #result_qfws1 = result_qfws2 = ""
    #mps.map_cons(2).each do |e|
    #  mp1, mp2 = e[0][1].map{|f|f[1]}, e[1][1].map{|f|f[1]}
    #  #kld = mp1.to_smt.kld(mp2.to_smt).to_f
    #  pmi = calc_mi( e[0][0], e[1][0] )
    #  metric = case o[:find_phrase]
    #           #when :kld : log2(1/kld+1.0)
    #           when :pmi : pmi
    #           else pmi
    #           end
    #  weight = (metric > 1)? 1 : 0
    #  result_qfws1 += "#{weight} #1(#{e[0][0]} #{e[1][0]}) " if weight > 0
    #  result_qfws2 += "#{weight} #uw1(#{e[0][0]} #{e[1][0]}) " if weight > 0
    #  #info "[get_prm_query] kld[#{e[0][0]}-#{e[1][0]}]\t#{kld.r3}\t#{metric}\t#{pmi}"
    #end
    #(result_qfws1.size>0)? "0.8 #combine(#{result}) 0.1 #weight(#{result_qfws1}) 0.1 #weight(#{result_qfws2})" : "1.0 #combine(#{result})"
  end

  #Herustic PRM
  def get_hprm_query(query, o={})
    topf_low = o[:topf_low] || 0.6
    topf_hi  = o[:topf_hi]  || 0.9
    mps = get_map_prob(query, o)
    mps_h = mps.map do |mp|
      top_field = mp[1].sort_by{|e|e[1]}.last
      if  top_field[1] > topf_hi
        [mp[0],[[top_field[0],1.0]]]
      elsif top_field[1] < topf_low  || top_field[0] == 'text' 
        [mp[0],[['BoW',1.0]]]
      else
        mp
      end
    end
    #info o.inspect
    #info mps_h.inspect
    #mps_h.each{|e| info "[get_hprm_query] #{e[0]} -> #{e[1].map{|f|[f[0],f[1].r3].join(':')}.join(' ')}"}
    return get_tew_query(mps_h, o)
  end

  #PRM with DQL
  def get_dprm_query(mps, lambdas, o={})
    queries = mps.map_with_index do |mp,i|
      "#wsum(#{lambdas[i]} #{get_tew_query([mp], o)} #{1-lambdas[i]} #{mp[0]})"
    end
    return queries.join("\n")
  end

  #Get Term-wise Element Weighting Query given Mapping Prob.
  def get_tew_query(mps, o)
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
    end
    mps_new.map{|mp| " #wsum(#{mp[1].sort_by{|e|e[1]}.reverse.map{|e|"#{e[1].r3} #{mp[0]}"+((e[0]!="BoW")? ".(#{e[0]})":"")}.join(' ')})" }.join("\n")
    #mps_new.map{|mp| " #wsum(#{mp[1].sort_by{|e|e[1]}.reverse.map{|e|"#{e[1].r3} #{mp[0]}.(#{e[0]})"}.join(' ')})" }.join("\n")
  end
  
  def get_hlm_query(query, weights, fields = nil)
    fields ||= $fields
    query.split(" ").map{|qw| s = weights.map_with_index{|w,i|"#{w} #{qw}.(#{fields[i]})"}.join(" ") ; " #wsum(#{s})" }.join(" ")
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
  
  #Get query expression for single query-term
  #mp = [query_term, [[field_1,weight_1], ...]]
  def get_query_from_mp(mp)
    "#wsum(#{mp[1].map{|e|"#{e[1]} #{mp[0]}.(#{e[0]})"}.join(" ")}) "
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
end
