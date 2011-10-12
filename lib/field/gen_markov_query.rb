module GenMarkovQuery
  ######## PARAMETER INITIALIZATION #########
  
  # Build FLM for term selection
  def get_mixture_flm(flm, terms, fields, weights)
    bi_flm, tri_flm = {}, {}
    if fields.size > 1 && fields[-1] == fields[-2]
      bi_flm = conv_to_unigram flm[2][fields[-1]], terms[-1]
    end
    #if fields.size > 2 && fields[-1] == fields[-2] && fields[-2] == fields[-3]
    #  tri_flm = conv_to_unigram flm[3][fields[-1]], [terms[-2], terms[-1]].join("_")
    #end
    flms = [flm[1][fields[-1]], get_dist_tfidf(flm[1][fields[-1]]), bi_flm] #, tri_flm
    result = {}
    0.upto( weights.size - 1 ) do |i|
      result = result.merge(flms[i]){|k,v1,v2| v1 + weights[i] * v2 }
    end
    #puts "[get_mixture_flm] tri_flm = #{tri_flm.inspect}" if tri_flm.size > 0
    result.to_p
  end
  
  def conv_to_unigram(lm, prefix)
    lm.map_hash{|k,v|
      k =~ /^#{prefix}_(.*)/
      [$1, v] if k
    }.to_p
  end
  
  # Train transition probability from relevant documents
  def train_trans_probs(queries, rlflms1)
    $trans = {}
    mpset = get_mpset_from_flms(queries, rlflms1).map{|e|mhash2arr e}
    mpset.each do |mps|
      0.upto( mps.size ) do |i|
        p mps.size if mps.size == 0
        curf = (i == 0)? "START" : mps[i-1][1][0][0]
        nextf = (i == mps.size)? "END" : mps[i][1][0][0]
        $trans[curf] = Hash.new(0) if !$trans[curf] 
        $trans[curf][nextf] += 1
      end
    end
    $trans
  end
  
  ######## QUERY GENERATION #########
  
  # Generate & evaluate markov queries
  def get_markov_queries(queries, rlflms, rlfvs, o = {})
    $mpset ||= get_mpset_from_flms(queries, rlflms.map{|e|e[1]}).
      map{|e|mhash2arr e}.map{|mps|mps.map{|e|e[1][0][0]}}
    $fdist ||= $mpset.flatten.to_dist.to_p
    $ldist ||= queries.map{|e|e.split(/\s+/).size}.to_dist.to_p
    
    rlflms.map_with_index do |flm,i|
      cands = [[queries[i].split(/\s+/).map{|e|kstem(e)}, $mpset[i]]]
      1.upto(o[:no_cand] || 20){|j| cands << generate_candidate(flm, o)}
      scores = cands.map do |c|
        #p c[0], c[0].size, $ldist[c[0].size]
        pos_score = calc_pos_score(c, rlfvs[i])
        stopword_ratio = (c[0].size > 0)? calc_stopword_feature(c[0]) : 0
        msngram_prob = calc_msngram_feature(c[0]).norm(-15, -5)
        [$ldist[c[0].size] || 0.0, 1/$fdist.kld_s( c[1].to_dist.to_p ), pos_score.mean, stopword_ratio, msngram_prob]
      end
      cands.map_with_index{|c,j| [c[0].join(" "), c[1].join(" "), scores[j].map{|e|e.to_f}].flatten}
    end
  end
  
  # Generate a markov query as a candidate
  def generate_candidate(dflms, o = {})
    terms, fields = [], []
    $doc_no ||= get_col_stat()[:doc_no]
    fields[0] = 'START'
      1.upto(o[:max_length] || 10) do |i|
        begin
          fields[i] = $trans[fields[i-1]].to_p.sample_pdist_except(fields.uniq - fields[-1..-1])[0]
          #p fields if fields[i] == 'END'
          break if fields[i] == 'END'
          mflm = get_mixture_flm(dflms, terms, fields[1..-1], (o[:mflm_weights] || [0.428, 0.142, 0.428]).to_p)
          terms << mflm.sample_pdist_except([terms,$stopwords.keys].flatten.uniq)[0]
        rescue Exception => e
          warn "[generate_candidates] Unable to generate a query! (#{e})"
          next
        end
      end
    [terms, fields[1..-2]]
  end
  
  ######## QUERY FEATURE CALCULATION #########
  
  def calc_pos_score(query_fields, fv)
    query_fields[0].map_with_index do |qw,j|
      if fv[query_fields[1][j]]
        pos_vec = fv[query_fields[1][j]].map_with_index{|e,k|(e == qw)? k : nil}
        pos_vec.find_all{|e|e}.map{|e|1.0 / (e+1)}.mean
      else
        0
      end
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
  
  ########### 
    
  def train_feature_weights(cand_set)
    result = [0, 0.25, 0.5, 0.75, 1].get_weight_comb(5).map do |weights|
      map = cand_set.map do |cands|
        recip_rank = nil
        begin
          rank_list = cands.map_with_index{|c,i| 
            [i , c[2..-1].map_with_index{|score,j|score * weights[j]}.sum]}.sort_by{|e|e[1]}.reverse          
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
  
  ############ MIXTURE WEIGHT TRAINING ############
  
  #load 'app/experiments/exp_optimize_method.rb'  
  def train_mixture_weights(queries, rlflms)
    results = []
    $doc_no ||= get_col_stat()[:doc_no]
    mpset = get_mpset_from_flms(queries, rlflms.map{|e|e[1]}).map{|e|mhash2arr e}
    
    #[0, 0.25, 0.5, 0.75, 1]
    [0, 0.25, 0.5, 0.75, 1].get_weight_comb(3).each do |weights|
      results << [weights , evaluate_mixture_weights(mpset, rlflms, weights)]
    end
    results.sort_by{|e|e[1]}
  end
  
  def evaluate_mixture_weights(mpset, rlflms, weights)
    total_result = 0
    mpset.each_with_index do |mps,i|
      mflm = {}
      terms, fields = [], []
      result = 0
      0.upto( mps.size-1 ) do |j|
        curt, curf = mps[j][0], mps[j][1][0][0]
        terms << curt ; fields << curf 
        mflm[curf] ||= get_mixture_flm(rlflms[i], terms, fields, weights)
        begin
          result += Math.log(mflm[curf][kstem(curt)])
        rescue Exception => e
          p e
          p mps[j]
          #p rlflms[i][curf]
          p mflm[curf]
        end
      end
      total_result += result #puts "result = #{result}"
    end
    total_result
  end
end