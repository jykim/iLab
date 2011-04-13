module GenHelper
  # Generate document with metadata from the collection
  # @param String doc_id
  # @param Array fields : {:tag=>, :content=>}
  def generate_doc(path, doc_id, fields , o = {})
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    File.open("#{path}/#{doc_id}.xml", "w"){|f| f.puts template.result(binding)}
    puts "[gen_doc] #{doc_id} file created"
  end
  
  # Get synthetic term distribution 
  def get_syn_tdist(prefix, term_no)
    (1..term_no).to_a.map_hash{|i|[prefix+i.to_s, 1.0/i]}
  end
  
  # Generate Collection Documents
  def build_collection(col_id, doc_no, field_no, mix_ratio = 0.5, term_no = 20, field_size = 10, doc_size = 200)
    clm = get_syn_tdist("c", term_no)
    flms = (1..field_no).to_a.map_hash{|i| 
      ["f#{i}", get_syn_tdist(i.to_s+"f", term_no).smooth(mix_ratio, clm)] }
    fsizes = flms.map_hash{|k,v|[k,field_size]}
    flms["clm"], fsizes["clm"] = clm, doc_size - field_size * field_no
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    #p flms

    File.open(to_path("#{col_id}.trecweb"),"w") do |f|
      1.upto(doc_no) do |i|
        doc_id = "D#{i}"
        fields = flms.map{|k,v|
          {:tag=>k, :content=>v.to_p.sample_pdist(fsizes[k]).join(" ")}}
        f.puts template.result(binding)
      end
    end
  end
  
  # Build known-item topic
  # o[:queries] : [[dno1, query1], [dno2, query2], ...]
  def build_knownitem_topics(file_topic, file_qrel, o={})
    queries = [] #o[:queries] 
    #results = []
    o[:topic_no] ||= 50
    #if o[:topic_prior]
    #  filepath_prior = "#{$col}_#{o[:topic_prior]}.prior"
    #  if !fcheck(filepath_prior)
    #    err "[build_knownitem_topics] No prior found! (#{filepath_prior})"
    #    return
    #  end
    #  o[:dids] = []
    #  $topic_docs = dsvread(filepath_prior).map{|l|[l[0],Math.exp(l[1])]}
    #  0.upto(o[:topic_no]-1){|i| o[:dids][i] = $topic_docs.dice}
    #end
    info "Total #{doc_no} / Chosen docs #{o[:dids].size}" if o[:dids]
    0.upto((o[:dids])? (o[:dids].size-1) : o[:topic_no]-1) do |i|    
      info "[build_knownitem_topics] did[#{i}] : #{o[:dids][i]}" if o[:dids]
      dno = (o[:dids])? to_dno(o[:dids][i]) : rand(doc_no)+1
      next unless dno > 0
      begin
        query = if o[:topic_type] =~ /^F_FF.*/
                  fields = $field_set[rand($field_set.size)]
                  get_knownitem_query(dno, o[:topic_type], fields.size, o.merge(:doc_no=>doc_no,:fields=>fields))
                else
                  topic_len = o[:query_len] || 3
                  get_knownitem_query(dno, o[:topic_type], topic_len, o.merge(:doc_no=>doc_no))
                end
        raise DataError, "No content in query!" if query.join(" ").blank?
        #results << get_doc_field_lm(dno)[1] #{:dno=>dno, :flm=>get_doc_field_lm(dno)}
      rescue Exception => e
        warn "[build_knownitem_topics] Unable to process doc ##{dno} (#{e})"
        next
      end
      queries << [to_did(dno).strip, query.join(" ")]
    end
    write_topic(to_path(file_topic), queries.map{|e|{:title=>e[1]}})
    write_qrel(to_path(file_qrel), queries.map_hash_with_index{|e,i|[i+1,{e[0]=>1}]})
    #return results
  end

  # Generate known-item topic given document and gen. method
  # - return P(term) if negativ length is given
  def get_knownitem_query(dno, topic_type, len = -1, o={})
    topic = []
    $doc_no ||= get_col_stat()[:doc_no]
    info "[get_knownitem_query] #{dno} #{topic_type}"
    case topic_type
    when /^D_/
      clm = get_col_freq()['document']
      dlm = get_doc_lm(dno)
      dlm_s = case topic_type
              when "D_RN"   : dlm.map_hash{|k,v|[k,1.0/dlm.size]}
              when "D_TF"   : dlm
              when 'D_IDF'  : get_dist_idf(dlm)
              when 'D_TIDF' : get_dist_tfidf(dlm)
              end
      #p "dlm = #{dlm_s.sort_by{|k,v|v}.reverse.inspect}"
      return dlm_s if len < 0
      1.upto(len){|j|topic << dlm_s.dice}
      
    when /^F_/
      cflm = get_col_freq()
      dflm = get_doc_field_lm(dno)[1]
      field_no = dflm.keys.size
      next if !dflm 
      dflm_s = case topic_type
               when /_RN$/   : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2,1.0/v.size]}]}
               when /_TF$/   : dflm
               when /_IDF$/  : dflm.map_hash{|k,v|[k,get_dist_idf(v)]}
               when /_TIDF$/ : dflm.map_hash{|k,v|[k,get_dist_tfidf(v)]}
               end
      return dflm_s.values.merge_elements if len < 0
      1.upto(len) do |j|
        field = case topic_type
                when /^F_MM/ : o[:fields][j]
                when /^F_RN/ : dflm.keys[rand(field_no)]
                else
                  topic_type.scan(/^F_([A-Za-z]+?)_/)[0][0]
                end
        topic << dflm_s[field].dice() if dflm_s[field]
      end
    else
      raise ArgError, "[get_knownitem_query] not a supported method! (#{topic_type})"
    end
    info "[get_knownitem_query] #{dno} | #{topic.join(" ")} | #{topic_type}"
    topic
  end
  
  def get_dist_idf(lm)
    dfh = get_df()
    lm.map_hash{|k,v|[k , Math.log($doc_no/dfh[k])]}.to_p
  end
  
  def get_dist_tfidf(lm)
    dfh = get_df()
    lm.map_hash{|k,v|[k , v*Math.log($doc_no/dfh[k])]}.to_p
  end
  
  def conv_to_unigram(lm, prefix)
    lm.map_hash{|k,v|
      k =~ /^#{prefix}_(.*)/
      [$1, v] if k
    }.to_p
  end
  
  # 
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
  
  def get_markov_query(dflms, length = 10)
    terms, fields = [], []
    $doc_no ||= get_col_stat()[:doc_no]
    fields[0] = 'START'
      1.upto(length) do |i|
        begin
          fields[i] = $trans[fields[i-1]].to_p.sample_pdist_except(fields.uniq - fields[-1..-1])[0]
          #p fields if fields[i] == 'END'
          break if fields[i] == 'END'
          mflm = get_mixture_flm(dflms, terms, fields[1..-1], [0.428, 0.142, 0.428].to_p)
          terms << mflm.sample_pdist_except(terms.flatten.uniq)[0]
        rescue Exception => e
          warn "[get_markov_query] Unable to generate a query!s (#{e})"
          next      
        end
      end      
    [terms, fields[1..-2]]
  end
  
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
  
  def calc_stopword_ratio(query)
    stopword_count = query.map{|q| $stopwords.has_key?(q)}.find_all{|e|e}.size
    (query.size - stopword_count) / query.size.to_f
  end
    
  def generate_candidates(queries, rlflms, rlfvs, o = {})
    $mpset ||= get_mpset_from_flms(queries, rlflms.map{|e|e[1]}).
      map{|e|mhash2arr e}.map{|mps|mps.map{|e|e[1][0][0]}}
    $fdist ||= $mpset.flatten.to_dist.to_p
    $ldist ||= queries.map{|e|e.split(/\s+/).size}.to_dist.to_p
    
    rlflms.map_with_index do |flm,i|
      #next if i > 1
      #puts "\n[evaluate_candidates] query = #{queries[i]}"
      cands = [[queries[i].split(/\s+/).map{|e|kstem(e)}, $mpset[i]]]
      1.upto(o[:no_cand] || 20){|j| cands << get_markov_query(flm)}
      scores = cands.map do |c|
        #p c[0]
        pos_score = calc_pos_score(c, rlfvs[i])
        stopword_ratio = (c[0].size > 0)? calc_stopword_ratio(c[0]) : 0
        [$ldist[c[1].size] || 0.0, 1/$fdist.kld_s( c[1].to_dist.to_p ), pos_score.mean, stopword_ratio]
      end
      cands.map_with_index{|c,j| [c[0].join(" "), c[1].join(" "), scores[j].map{|e|e.to_f}].flatten}
    end 
  end
  
  def train_comb_weights(cand_set)
    result = [0, 0.25, 0.5, 0.75, 1].get_weight_comb(4).map do |weights|
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
  
  # Get generation probability of given query and reldoc ID using given topic_type
  def get_gen_prob(query, dno, topic_type, o={})
    p_term = get_knownitem_query(dno, topic_type, -1, o)
    result = 0.0
    query.split(" ").each_with_index do |qw,i|
      #Read Collection Stat.
      qw_s = kstem(qw.downcase)
      info "[get_gen_prob] #{qw_s} = #{p_term[qw_s]}"
      result += Math.log(p_term[qw_s]) if p_term[qw_s] && p_term[qw_s] > 0
    end
    result
  end  
end
