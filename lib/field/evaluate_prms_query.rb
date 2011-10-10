module PRMHelper
  
  # Run PRM-S query given query & docids
  def debug_prm_query(qno, retmodel, docids = nil, o = {})
    case retmodel
    when :mflm
      types, weights = [:prior],[1]
    when :prms
      types, weights = [:cug],[1]
    when :ora
      types, weights = [:ora],[1]
    when :mix
      types, weights = $mp_types, $mix_weights
    else
      return nil
    end
    
    op_comb = o[:op_comb] || :wsum
    op_smt = o[:op_smt] || :field
    sparam = o[:sparam] || 0.1
    
    qidx = qno - $offset
    mps = get_mixture_mpset([$queries[qidx]], types, weights, :qno=>qno)[0]
    
    return get_tew_query(mps) if !docids
    #return get_mp_tbl(mps) if !docids
    
    clm = get_col_freq(:whole_doc=>true, :prob=>true)
    cflm = get_col_freq(:prob=>true)
    docids.each do |did|
      score_doc = 0
      dflm = get_doc_field_lm(did, 1)[1]
      dfl = get_doc_field_length(did)
      mps.each_with_index do |mp,i|
        score_qw = 0
        qw = kstem(mp[0])
        mp[1].each_with_index do |e,j|
          bglm = (op_smt == :field) ? cflm[e[0]] : clm
          lambda = (sparam < 1) ? sparam : sparam.to_f / (dfl[e[0]] + sparam)
          ql = (1-lambda) * (dflm[e[0]][qw] || 0.0) + lambda * (bglm.to_p[qw] || 1 / (bglm.size * 2.0))
          puts "         #{(ql * e[1]).round_at(6)}\t= #{ql.round_at(6)} * #{e[1].r3} <- #{qw}/#{e[0]}/#{lambda.r3}"
          #puts "         #{(slog(ql) * e[1]).round_at(6)}\t= #{slog(ql).round_at(6)} * #{e[1].r3} <- #{qw}/#{e[0]}"
          (op_comb == :weight) ? score_qw += slog(ql) * e[1] : score_qw += ql * e[1]
        end
        puts "#{slog(score_qw).r3}"
        score_doc += ((op_comb == :weight) ? score_qw : slog(score_qw))
      end
      puts "#{(score_doc / mps.size).r3 } <- TotalScore(#{did})\n\n"
    end
  end
end