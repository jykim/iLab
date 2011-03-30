module PRMMulticolHelper
  
  def get_clm_by_col()
    @clm ||= get_col_freq().group_by{|k,v|k.split("_")[0]}.map_hash{|k,v|[k, v.to_h.values.merge_elements.to_p]}
  end
  
  # Normalize and weight mapping probability for each collection
  # mp = {f1=>mp1, f2=>mp2, ...}
  # col_scores = {col1=>score1, }
  def scale_map_prob(qw, mp, cs_type, o)
    cs_smooth = o[:cs_smooth] || 0.1
    mp_group = mp.group_by{|k,v|k.split("_")[0]}
    col_scores = $col_types.map_hash { |col|
      #debugger
      unless mp_group[col]
        [col,0.0]
      else
        case cs_type
        when :uniform
          [col, 1.0]
        when :mpmax
          [col, mp_group[col].max{|a,b|a[1]<=>b[1]}[1]]
        when :mpmean
          [col, mp_group[col].map{|e|e[1]}.mean]
        when :cql
          [col, (get_clm_by_col()[col][qw] || 0.0001)]
        end
      end
    }.to_p.smooth(cs_smooth)
    debug "[scale_map_prob] #{qw} : #{col_scores.to_a.sort_val.inspect}"
    #debugger
    col_scores
  end
  
  def get_cs_score(q, cs_type, o={})
    col_score_def = 0.0001
    mpmax_smooth = o[:mpmax_smooth] || 0.3
    if $csel_scores && $csel_scores[q.qid] && $csel_scores[q.qid][cs_type]
      puts "[csel_scores] #{q.qid} / #{cs_type} used"
      return $csel_scores[q.qid][cs_type] 
    end
    cs_score = if cs_type == :uniform
      $col_types.map_hash{|e|[e,1.0]}.to_p
    else
      mps = get_map_prob(q.text)
      col_scores = mps.map_hash do |mp|
        qw = mp[0]
        mp_group = mp[1].group_by{|e|e[0].split("_")[0]}
        col_scores_qw = $col_types.map_hash { |col|
          #debugger
          unless mp_group[col]
            [col,col_score_def]
          else
            case cs_type
            when :uniform
              [col, 1.0]
            when :best
              [col, (($qid_type[q.qid]==col)? 1.0 : 0.0)]
            when :mpmax
              [col, mp_group[col].max{|a,b|a[1]<=>b[1]}[1]]
            when :mpmean
              [col, mp_group[col].map{|e|e[1]}.mean]
            when :cql
              [col, (get_clm_by_col()[col][qw] || col_score_def)]
            end
          end#col_scores_qw
        }.to_p
        #debug "[get_cs_score] #{qw} : #{col_scores_qw.to_a.sort_val.inspect}"
        [qw,col_scores_qw]
      end#col_scores
      col_scores.values.merge_by_product.to_p
    end#cs_score
    #debugger
    $csel_scores[q.qid] ||= {}
    $csel_scores[q.qid][cs_type] = cs_score
    #$csel_scores[q.qid][:mpmeancql] = $csel_scores[q.qid][:mpmean].smooth(mpmax_smooth, $csel_scores[q.qid][:cql]) if $csel_scores[q.qid][:mpmean] 
    #$csel_scores[q.qid][:mpmaxcql] = get_cs_score(q.qid,:mpmax).smooth(mpmax_smooth, get_cs_score(q.qid, :cql)) if $csel_scores[q.qid][:mpmax] 
    info "[get_cs_score] #{cs_type} | #{q.qid} : #{cs_score.r3.to_a.sort_val.inspect}"
    cs_score
  end
  
  #PRM-S with multiple sub-collections
  def get_multi_col_query(query, o={})
    col_scores = get_cs_score(query, o[:cs_type], o)
    info "[get_multi_col_query] col_scores = #{col_scores.inspect}"
    result = $fields.group_by{|e|e.split('_')[0]}.map do |col,fields|
      sub_query = get_prm_query(query, o.merge(:prm_fields=>fields,:cs_type=>nil))
      "#{col_scores[col]} #combine(#{sub_query}) "
    end
    return "#wsum(#{result.join("\n")})"
  end

  #PRM with DQL
  def get_dprm_query(mps, lambdas, o={})
    queries = mps.map_with_index do |mp,i|
      "#wsum(#{lambdas[i]} #{get_tew_query([mp], o)} #{1-lambdas[i]} #{mp[0]})"
    end
    return queries.join("\n")
  end
end