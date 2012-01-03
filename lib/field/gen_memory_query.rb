module GenMemoryQuery
  def gen_mem_model(rlflms, fweights = {})
    rlflms.map do |flm|
      result = {}
      flm[2].each do |field,lm|
        lm.each do |bigram, count|
          e = bigram.split("_")
          result[e[0]] = {} if !result[e[0]]
          result[e[0]][e[1]] = 0 if !result[e[0]][e[1]]
          result[e[0]][e[1]] += count * (fweights[field] || 1.0)
        end
      end
      # Start Prob. Initialize
      base_activ = flm[1].values.merge_by_sum()
      inter_activ = result.map_hash do |w1, words|
        [w1, words.map_hash{|w2,v|[w2,(v.to_f / base_activ[w1] / base_activ[w2])] }.to_p]
      end
      {:base=>base_activ.to_p, :inter=>inter_activ}
    end
  end
  
  def export_mem_model(filename, mem_model, query_nodes, o = {})
    type = o[:type] || 'dot'
    template = ERB.new(IO.read(to_path("graph_#{type}.erb")))
    nodes = query_nodes
    edges = []
    mem_model[:inter].each do |w1, words|
      words.each do |w2, count|
        edges << {:from=>w1, :to=>w2, :weight=>1, :label=>count.r3} if count > (o[:threshold] || 1)
      end
    end        
    File.open("#{filename}.#{type}" , "w"){|f| f.puts template.result(binding) }
    puts "created a #{type} file..."
    puts cmd = "#{type} -T png -o #{filename}.png #{filename}.#{type}"
    `#{cmd}`
  end
  
  #def trim_stopwords(query)
  #  start_with_stop = true
  #  0.upto(query.size-1) do |i|
  #    if start_with_stop
  #      query
  #    end
  #  end
  #end
  
  def estimate_prob_restart(queries_a, rlflms)
    prob_restart = []
    queries_a.each_with_index{|qt,i|
      rlm2 = rlflms[i][2].values.merge_by_sum()
      qt.each_cons(2){|e| prob_restart << (rlm2[e.join("_")] ? 1 : 0) }
    }
    prob_restart.sum / prob_restart.size.to_f
  end
  
  def gen_memory_query(mem_model, o = {})
    start_prob = {}
    prob_restart = o[:prob_restart] || $prob_restart
    #max_length = o[:max_length] || 5
    results = []
    #clm = get_col_freq(:whole_doc=>true, :prob=>true)
    #bclm = get_col_freq(:whole_doc=>true,:bgram=>true)

    0.upto((o[:no_cand] || 20)-1) do |i|
      qry_length = o[:qry_length] || $ldist.sample_pdist.first
      #qry_length = (qry_length > max_length)? max_length : qry_length
      results[i] = []
      while(true)
        next_term = mem_model[:base].smooth(o[:smooth_ratio] || 0.0, o[:smooth_lm]).sample_pdist[0]
        (results[i].find{|e|e == next_term}) ? next : (results[i] << next_term)
        #p "QW[0] = #{results[i][0]} : #{start_prob.to_p[results[i][0]]} -> #{start_prob_s[results[i][0]]}"
        1.upto(qry_length - results[i].size) do |j|
          if rand() > (1-prob_restart) && mem_model[:inter][results[i][-1]]
            next_term = mem_model[:inter][results[i][-1]].sample_pdist[0]
            results[i] << next_term unless results[i].find{|e|e == next_term}
            #p mem_model[results[i][-1]] if o[:verbose]
          else
            break
          end
        end
        break if results[i].size >= qry_length
      end
    end
    results
  end
end