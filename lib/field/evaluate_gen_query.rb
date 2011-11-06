module EvaluateGenQuery
  
  ######## QUERY FEATURE CALCULATION #########
  
  def calc_pos_score(query_fields, fv)
    query_fields[0].map_with_index do |qw,j|
      pos_vec = fv.map{|k,v| v.map_with_index{|e,k|(e == qw)? k : nil} }.flatten
      pos_vec.find_all{|e|e}.map{|e|1.0 / (e+1)}.mean
    end
  end
  
  def calc_stopword_feature(query)
    stopword_count = query.map{|q| $stopwords.has_key?(q)}.find_all{|e|e}.size
    stopword_ratio = (stopword_count) / query.size.to_f
    stopword_feature = (stopword_ratio < 0.5) ? 1.0 : (-2 * stopword_ratio + 2)
    #puts ""
  end
  
  def calc_msngram_feature(query)
    request_str = query.map_cons(2).map{|e|e.join(" ")}.join("\n")
    get_msngram("jp", request_str).avg
  end
  
  def calc_feature_set(queries_a, cand_set, rlfvs, o = {})
    #1/$fdist.kld_s( c[1].to_dist.to_p ), 
    $ldist ||= queries_a.map{|e|e.size}.to_dist.to_p
    cand_set.map_with_index do |cands,i|
      cands_new = [queries_a[i]].concat cands
      if o[:skip_calc_feature]
        scores = scores = cands_new.map do |c|
          [0,0,0,0]
        end
      else
        scores = cands_new.map do |c|
          #p c[0], c[0].size, $ldist[c[0].size]
          pos_score = calc_pos_score(c, rlfvs[i])
          stopword_ratio = (c.size > 0)? calc_stopword_feature(c) : 0
          msngram_prob = calc_msngram_feature(c).norm(-15, -5)
          [$ldist[c.size] || 0.0, pos_score.mean, stopword_ratio, msngram_prob]
        end
      end
      cands_new.map_with_index{|c,j| [c.join(" "), scores[j].map{|e|e.to_f}].flatten}
    end
  end
  
  ########### 
  
  def train_feature_weights(cand_set)
    result = [0, 0.25, 0.5, 0.75, 1].get_weight_comb(4).map do |weights|
      map = cand_set.map do |cands|
        recip_rank = nil
        begin
          rank_list = cands.map_with_index{|c,i| 
            [i , c[1..-1].map_with_index{|score,j|score * weights[j]}.sum]}.sort_by{|e|e[1]}.reverse          
          rank_list.each_with_index{|e,i| recip_rank = 1.0 / (i+1) if e[0] == 0 }
        rescue Exception => e
          p [cands, e.to_s]
          recip_rank = 0
        end
        #p [rank_list, recip_rank]
        recip_rank
      end
      #p [weights, map.mean]
      [weights, map.mean]
    end
    result.sort_by{|e|e[1]}
  end
  
end