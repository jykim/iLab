#Functions Related to PRM
#
module PRMHelper
  #Collection Frequency
  # o[:prob] : return probability instead
  # return : {'FIELD1'=>{term1=>prob1,...},... }
  def get_col_freq(o = {})
    cf_fn = "FREQ_#{File.basename(@index_path)}_#{o[:whole_doc]}.in"
    if !File.exist?(to_path(cf_fn))
      calc_col_freq( to_path(cf_fn), :whole_doc=>o[:whole_doc])
      puts "[get_col_freq] Creating #{cf_fn}..."
    end
    if !@cf[o.to_s]
      cf_raw = IO.read(to_path(cf_fn)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      @cf[o.to_s] = ((o[:prob])? cf_raw.map_hash{|k,v|[k,v.to_p]} : cf_raw)
    else
      @cf[o.to_s]
    end
  end
  
  # Build known-item topic
  # o[:queries] : [[dno1, query1], [dno2, query2], ...]
  def build_knownitem_topics(file_topic, file_qrel, o={})
    queries = [] #o[:queries] 
    o[:topic_no] ||= 50
    doc_no = get_col_stat()[:doc_no]
    if o[:topic_prior]
      filepath_prior = "#{$col}_#{o[:topic_prior]}.prior"
      if !fcheck(filepath_prior)
        err "[build_knownitem_topics] No prior found! (#{filepath_prior})"
        return
      end
      o[:dids] = []
      $topic_docs = dsvread(filepath_prior).map{|l|[l[0],Math.exp(l[1])]}
      0.upto(o[:topic_no]-1){|i| o[:dids][i] = $topic_docs.dice}
    end
    info "Total #{doc_no} / Chosen docs #{o[:dids].size}" if o[:dids]
    0.upto((o[:dids])? (o[:dids].size-1) : o[:topic_no]-1) do |i|    
      info "[build_knownitem_topics] did[#{i}] : #{o[:dids][i]}" if o[:dids]
      dno = (o[:dids])? to_dno(o[:dids][i]) : rand(doc_no)+1
      next unless dno > 0
      begin
        query = if o[:topic_type] =~ /^F_FF.*/
                  fields = $field_set[rand($field_set.size)]
                  get_knownitem_topic(dno, o[:topic_type], fields.size, o.merge(:doc_no=>doc_no,:fields=>fields))
                else
                  topic_len = o[:query_len] || 2#(o[:query_len])? o[:query_len] : $query_lens[rand($query_lens.size)]
                  get_knownitem_topic(dno, o[:topic_type], topic_len, o.merge(:doc_no=>doc_no))
                end
      rescue => err
        info "[build_knownitem_topics] Unable to process doc ##{dno} (#{err})"
        next
      end
      queries << [to_did(dno).strip, query.join(" ")]
    end
    write_topic(to_path(file_topic), queries.map{|e|{:title=>e[1]}})
    write_qrel(to_path(file_qrel), queries.map_hash_with_index{|e,i|[i+1,{e[0]=>1}]})
  end

  # Generate known-item topic given document and gen. method
  # - return P(term) if negativ length is given
  def get_knownitem_topic(dno, topic_type, len = -1, o={})
    dfh = get_df()
    topic = []
    info "[get_knownitem_topic] #{dno} #{topic_type} (replace=#{o[:replace]})"
    case topic_type
    when /^D_/
      clm = get_col_freq(:whole_doc=>true)
      dlm = get_doc_lm(dno)
      info "DLM size : #{dlm.size}"
      dlm_s = case topic_type
              when "D_RN"   : dlm.map_hash{|k,v|[k,1.0/dlm.size]}
              when "D_TF"   : dlm
              when 'D_IDF'  : dlm.map_hash{|k,v|[k,Math.log(o[:doc_no]/dfh[k])]}.to_p
              when 'D_TIDF' : dlm.map_hash{|k,v|[k,v*Math.log(o[:doc_no]/dfh[k])]}.to_p
              end
      #p "dlm = #{dlm_s.sort_by{|k,v|v}.reverse.inspect}"
      return dlm_s if len < 0
      1.upto(len){|j|topic << dlm_s.dice}
      
    when /^F_/
      cflm = get_col_freq()
      dflm = get_doc_field_lm(dno)
      field_no = dflm.keys.size
      next if !dflm #|| dflm.keys.size != cflm.keys.size
      #assert_equal(dflm.keys.sort , cflm.keys.sort, 'DFLM != CFLM')
      dflm_s = case topic_type
               when /_RN$/   : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2,1.0/v.size]}]}
               when /_TF$/   : dflm
               when /_IDF$/  : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2, Math.log(o[:doc_no]/dfh[k2])]}.to_p]}
               when /_TIDF$/ : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2, v2*Math.log(o[:doc_no]/dfh[k2])]}.to_p]}
      end
      return dflm_s.merge_elements if len < 0
      1.upto(len) do |j|
        field = case topic_type
                when /^F_FF/ : o[:fields][j]
                when /^F_RN/ : dflm.keys[rand(field_no)]
                else
                  topic_type.scan(/^F_([A-Za-z]+?)_/)[0][0]
                end
        #puts "[get_knownitem_topic] field = #{field} (#{dflm_s.keys})"
        #p "dflm = #{dflm_s.map{|k,v|v.sort_by{|k,v|v}.reverse}.inspect}"
        #xp "field = #{field}"
        topic << dflm_s[field].dice(o[:replace]) if dflm_s[field]
      end
    when /^EN_/
      dlm = get_doc_lm(dno)
      dent = dlm.keys.map do |w|
        mp = get_col_freq.map_hash{|k,v| [k,v[w]] if v[w] && $fields.include?(k)}
        [w, mp.values.h]
      end
      ent_list = dent.find_all{|e|e[1] > 0}.sort_by{|e|e[1]}
      
      1.upto(len) do |j|
        topic << case topic_type
        when /L$/ #Low entropy -> skewed MP distribution
          ent_list.to_h.inverse.dice(o[:replace])
        when /H$/
          ent_list.dice(o[:replace])
        end
      end
      #info "[get_knownitem_topic] ent_list: #{ent_list.inspect}"
    else
      raise ArgError, "[get_knownitem_topic] not a supported method! (#{topic_type})"
    end
    #0.upto(topic.size-1){|i| topic[i] = "QWERTYUIOP" if rand() <= (o[:noise_ratio] || 0.1)}
    info "[get_knownitem_topic] #{dno} | #{topic.join(" ")} | #{topic_type}"
    topic
  end
  
  # Get generation probability of given query and reldoc ID using given topic_type
  def get_gen_prob(query, dno, topic_type, o={})
    p_term = get_knownitem_topic(dno, topic_type, -1, o)
    result = 0.0
    query.split(" ").each_with_index do |qw,i|
      #Read Collection Stat.
      qw_s = kstem(qw.downcase)
      info "[get_gen_prob] #{qw_s} = #{p_term[qw_s]}"
      result += Math.log(p_term[qw_s]) if p_term[qw_s] && p_term[qw_s] > 0
    end
    result
  end
  
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
    #info "[scale_map_prob] #{qw} : #{col_scores.r3.sort_val.inspect}"
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
    cs_scores_all = col_scores.map_hash{|k,v|[k,v.to_log]}.merge_elements.r3.sort_val
    $top_cols[query] ||= {}
    $top_cols[query][o[:cs_type]] = cs_scores_all[0][0]
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
