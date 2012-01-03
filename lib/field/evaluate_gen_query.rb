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
  end
  
  def calc_postag_score(query, query_postags , o={})
    #puts "#{query.inspect} -> #{query_postags}"
    postags = ["START", query_postags.split(/\s+/).map{|e|e.split("_")[1]}[0..-2], "END"].flatten
    trans_probs = []
    gen_probs = postags.map{|e| $gen_pos[e] || 0.0 }
    postags.each_cons(2) do |e|
      #debugger
      trans_probs << if $trans_pos[e[0]] && $trans_pos[e[0]][e[1]] > 0
        $trans_pos[e[0]].to_p[e[1]]
      else
        0.0
      end
    end
    puts "[#{o[:qid]}:POS:] #{postags.inspect} : #{gen_probs.avg.r3} : #{trans_probs.avg.r3} = #{gen_probs.map{|e|e.r3}.inspect} : #{trans_probs.map{|e|e.r3}.inspect}" if $o[:verbose]
    [trans_probs.first, trans_probs.last, gen_probs.avg, trans_probs.avg]
  end
  
  def calc_msngram_feature(query , o={})
    request_str = query.join("\n")
    msngram_scores = get_msngram("jp", request_str)
    request_str2 = query.map_cons(2).map{|e|e.join(" ")}.join("\n")
    msngram_scores2 = get_msngram("jp", request_str2)
    puts "[#{o[:qid]}:MSN:] #{query.inspect} : #{msngram_scores.avg.r3} : #{msngram_scores2.avg.r3} = #{msngram_scores.map{|e|e.r3}.inspect} : #{msngram_scores2.map{|e|e.r3}.inspect}" if $o[:verbose]
    [msngram_scores.first, msngram_scores2.first]
  end
  
  def calc_idf_feature(query , o={})
    idfs = query.map{|q|$idfh[q]}.find_all{|e|e}
    puts "[#{o[:qid]}:IDF:] #{query.join(" ")} : #{idfs.avg.r3} = #{idfs.map{|e|e.r3}.inspect}" if $o[:verbose]
    idfs.avg
  end
  
  def calc_feature_set(queries_a, cand_set, rlfvs, rldids, o = {})
    #1/$fdist.kld_s( c[1].to_dist.to_p ), 
    cand_set.map_with_index do |cands,i|
      cands_new = [queries_a[i]].concat cands
      if o[:skip_feature]
        features = features = cands_new.map do |c|
          [0] * $features.size
        end
      else
        features = cands_new.map_with_index do |c,j|
          #p c[0], c[0].size, $ldist[c[0].size]
          pos_score = calc_pos_score(c, rlfvs[i])
          #stopword_ratio = (c.size > 0)? calc_stopword_feature(c) : 0
          idf_score = calc_idf_feature(c, :qid=>j)
          msn_prob = calc_msngram_feature(c, :qid=>j)
          postags = (j == 0)? $pos_queries[i] : $pos_cands[i*$o[:no_cand]+j-1]
          postag_score = calc_postag_score(c, postags, :qid=>j)
          [$ldist[c.size] || 0.0, pos_score.mean, idf_score/3, msn_prob[0].norm(-6, -2), msn_prob[1].norm(-10, -5), postag_score].flatten
        end
      end
      cands_new.map_with_index{|c,j| [c.join(" "), rldids[i] ,features[j].map{|e|e.to_f}].flatten}
    end
  end
  
  ########### 
  def evaluate_cand_set(cand_set, weights)
    cand_set.map do |cands|
      recip_rank = nil
      begin
        rank_list = cands.map_with_index{|c,i| 
          #p c[1..-1], weights
          [i , c[2..-1].map_with_index{|score,j|score * weights[j]}.sum]}
        #p rank_list
        rank_list_sort = rank_list.sort_by{|e|e[1]}.reverse          
        rank_list_sort.each_with_index{|e,i| recip_rank = 1.0 / (i+1) if e[0] == 0 }
      rescue Exception => e
        #p [cands, e.to_s]
        recip_rank = 0
      end
      #p [rank_list, recip_rank]
      recip_rank
    end
  end
  
  def train_weights_by_grid(cand_set)
    result = [0, 0.25, 0.5, 0.75, 1].get_weight_comb($features.size).map do |weights|
      perf = evaluate_cand_set(cand_set, weights)
      #p [weights, map.mean]
      [weights, perf.mean]
    end
    result.sort_by{|e|e[1]}
  end
  
  # @param <Array> : input_data (same as evaluate_sim_search_with)
  # @param <String> output : output file
  # @return <String> : type
  def train_weights_by_cascent(cand_set, o={})
    xvals = (1..($features.size-1)).to_a
    yvals = [] ; yvals << [0.5] * xvals.size
    results = []
    search_method = GoldenSectionSearchMethod.new(xvals , yvals)
    search_method.search(3) do |xvals , yvals , train , remote|
      results << [yvals, evaluate_cand_set(cand_set, yvals).mean]
      results[-1][-1]
    end
    #debugger
    results_str = results.sort_by{|e|e[1]}
  end
  
  
  def train_weights_by_ranksvm(cand_set, o = {})
    if o[:train_file]
      filename = o[:train_file]
    else
      filename = to_path("svm_train_#{$query_prefix}_#{$o[:new_topic_id]}.in")
      generate_input_ranksvm(cand_set, filename)
    end
    best_params = $engine.train_parameter(filename,:folds=>10)
    puts "[train_weights_by_ranksvm] best_params = #{best_params.inspect}"
    run_ranksvm(filename, :tradeoff=>best_params.sort_by{|k,v|v}[-1][0])
  end
end