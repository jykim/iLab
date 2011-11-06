module GenMemoryQuery
  def gen_term_graph(rlflms, fweights = {})
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
      result
    end
  end
  
  def export_term_graph(filename, term_graph, query_nodes, o = {})
    type = o[:type] || 'dot'
    template = ERB.new(IO.read(to_path("graph_#{type}.erb")))
    nodes = query_nodes
    edges = []
    term_graph.each do |w1, words|
      words.each do |w2, count|
        edges << {:from=>w1, :to=>w2, :weight=>count, :label=>count} if count > (o[:threshold] || 1)
      end
    end        
    File.open("#{filename}.#{type}" , "w"){|f| f.puts template.result(binding) }
    puts "created a #{type} file..."
    puts cmd = "#{type} -T png -o #{filename}.png #{filename}.#{type}"
    `#{cmd}`
  end
  
  def trim_stopwords(query)
    start_with_stop = true
    0.upto(query.size-1) do |i|
      if start_with_stop
        query
      end
    end
  end
  
  def gen_memory_query(term_graph, o = {})
    start_prob = {}
    results = []
    #clm = get_col_freq(:whole_doc=>true, :prob=>true)
    #bclm = get_col_freq(:whole_doc=>true,:bgram=>true)

    # Start Prob. Initialize
    term_graph.map do |w1, words|
      start_prob[w1] = words.values.sum
      #bclm_unig = conv_to_unigram(bclm, w1)
      words.to_p#.smooth(o[:smooth_trans] || 0.1, bclm_unig)
    end
    if o[:smooth_lm]
      start_prob_s = start_prob.to_p.smooth(o[:smooth_ratio] || 0.1, o[:smooth_lm])
    else
      start_prob_s = start_prob
    end
    0.upto(o[:no_cand] || 20) do |i|
      results[i] = []
      results[i] << start_prob_s.sample_pdist[0]
      #p "QW[0] = #{results[i][0]} : #{start_prob.to_p[results[i][0]]} -> #{start_prob_s[results[i][0]]}"
      1.upto(5) do |j|
        if term_graph[results[i][-1]]
          next_term = term_graph[results[i][-1]].sample_pdist[0]
          results[i] << next_term unless results[i].find{|e|e == next_term}
          #p term_graph[results[i][-1]] if o[:verbose]
        else
          break
        end
      end
    end
    results
  end
end