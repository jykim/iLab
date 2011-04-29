module IndriFieldHelper
  #Collection Frequency
  # o[:prob] : return probability instead
  # return : {'FIELD1'=>{term1=>prob1,...},... }
  def get_col_freq(o = {})
    cf_fn = "FREQ_#{File.basename(@index_path)}.in"
    df_fn = "DOC_FREQ_#{File.basename(@index_path)}.in"
    bgram_fn = "BGRAM_FREQ_#{File.basename(@index_path)}.in"
    if !File.exist?(to_path(cf_fn)) || !File.exist?(to_path(bgram_fn))
      cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{to_path(cf_fn)} #{to_path(bgram_fn)}", :mode=>'a')
      #cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{to_path(cf_fn)}", :mode=>'a')
      #cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{to_path(cf_fn)} #{to_path(df_fn)} #{to_path(bgram_fn)}", :mode=>'a')
      `#{cmd}`
    end
    parse_col_freq(cf_fn)
    parse_col_freq(bgram_fn, :bgram=>true)
    #parse_col_freq(df_fn, :df=>true)
    $cf[o.to_s]
  end
  
  def parse_col_freq(filename, o = {})
    if !$cf[o.to_s]
      cf_raw = IO.read(to_path(filename)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      puts "[parse_col_freq] reading #{filename} (#{o.inspect})..."
      #puts "[parse_col_freq] Fields read : #{cf_raw.keys.inspect}"
      $cf[o.to_s] = cf_raw
      $cf[o.merge(:prob=>true).to_s] = cf_raw.map_hash{|k,v|[k,v.to_p]}
    end
  end
  
  def get_doc_lm(dno)
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)
    words = dv[2].split("\n").map{|l|l.split(" ")}.map{|e|e[2]}
    get_unigram_lm(words)
  end
  
  # Get the field-level term vector for given document
  def get_doc_field_vector(dno)
    return $dfv[dno] if $dfv[dno]
    dno = to_dno(dno) if dno.class == String
    return nil if !dno
    
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)    
    # Get the range of each field
    fields = dv[1].split("\n").find_all{|l|!l.include?("document ")}.
      map_hash{|l|e = l.split(" ") ; [(e[1].to_i...e[2].to_i) , e[0]]}
    #return nil if fields.values.size !=  fields.values.uniq.size
    $dfv[dno] = dv[2].split("\n").map{|l|l.split(" ")}.
      group_by{|e|f = fields.find{|k,v|k === e[0].to_i} ; (f)? f[1] : nil }.
      map_hash{|k,v|[k, v.map{|e|e[2]}]}
  end
  
  def get_doc_field_lm(dno, n = 1)
    #return $dflm[dno] if $dflm[dno]
    results = {}
    field_terms = get_doc_field_vector(dno)
    1.upto(n) do |i|
      if i == 1
        results[i] = field_terms.map_hash{|k,v|[ k , get_unigram_lm(v) ]}
      else
        results[i] = field_terms.map_hash{|k,v|[ k , get_ngram_lm(v, i) ]}
      end
    end
    results
    #$dflm[dno] = results
  end
  
  def get_unigram_lm(words)
    words.find_all{|e|e != "[OOV]"}.to_pdist
  end
  
  def get_ngram_lm(words, n)
    result = []
    words.each_cons(n){|ngram|result << ngram unless ngram.find{|word|word == "[OOV]"}}
    result.group_by{|e|e}.map_hash{|k,v| [k.join("_"), v.size] }
  end
  
  def get_doc_field_text(dno, fields)
    dno = to_dno(dno) if dno.class == String
    return nil if !dno
    dt = get_index_info("dt", dno)
    fields.map do |field|
      dt.find_tag(field)[0].clear_tags().strip
    end
  end
  
  def annotate_text_with_query(text, query, fields)
    query_s = query.scan(/\w+/).map_hash_with_index{|qw,i|[kstem(qw), i]}
    fields.map_with_index do |field,i|
      text[i].scan(/\W+|\w+/).map_with_index{|token, j|
        word = token.scan(/\w+/)[0]
        if word && (n_qw = query_s[kstem(word)])
            "[#{n_qw}]#{token}"
        else
          token
        end
      }.join("")
    end
  end
  
  # Get the list and LM of relevant docs from TREC QRel
  def get_rel_flms( file_qrel, n = 1 )
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      get_doc_field_lm(l.split(" ")[2], n)
    end
  end
  
  # Get the list and term vectors of relevant docs from TREC QRel
  def get_rel_fvs( file_qrel)
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      get_doc_field_vector(l.split(" ")[2])
    end
  end
  
  # Get the list and LM of relevant docs from TREC QRel
  def get_rel_texts( file_qrel)
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      qrel_finename = l.split(" ")[2]
      [qrel_finename, get_doc_field_text(qrel_finename , $fields)]
    end
  end
  
  # Get FLM from top K result documents
  def get_res_flm( res_docs, n = 2)
    max_score = res_docs[0].score
    result = {1=>nil, 2=>nil}
    nscores = res_docs.map{|e|e.score - max_score}.map{|e|Math.exp(e)}
    
    result.map_hash do |ng,v| #iterate through all n-grams
      result_n = v
      
      res_docs.each_with_index do |d,i|
        dflm = get_doc_field_lm(d.did, n)[ng]
        #p dflm.keys
        if !result_n
          result_n = dflm
        else
          result_n = result_n.map_hash{|k,v|
            dflm[k] = {} if !dflm[k]
            [k,v.sum_prob(dflm[k].map_hash{|k2,v2|[k2, v2 * nscores[i]]})]}
        end
      end
      [ng, result_n]
    end
  end
  
end