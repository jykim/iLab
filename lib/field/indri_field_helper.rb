$bgcolors = ['#FF0000',
'#0000FF',
'#0000A0',
'#FF0080',
'#800080',
'#FF00FF',
'#FFFFFF',
'#C0C0C0',
'#808080',
'#000000',
'#FFA500',
'#A52A2A',
'#800000',
'#008000',
'#808000']

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
    parse_col_freq(bgram_fn, :bgram=>true) if o[:bgram]
    #parse_col_freq(df_fn, :df=>true)
    $cf[o]
  end
  
  def parse_col_freq(filename, o = {})
    if !$cf[o]
      cf_raw = IO.read(to_path(filename)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      puts "[parse_col_freq] reading #{filename} (#{o.inspect})..."
      #puts "[parse_col_freq] Fields read : #{cf_raw.keys.inspect}"
      $cf[o.merge(:whole_doc=>true)] = cf_raw['document']
      $cf[o.merge(:whole_doc=>true,:prob=>true)] = cf_raw['document'].to_p
      cf_raw.delete('document')
      $cf[o.merge(:prob=>true)] = cf_raw.map_hash{|k,v|[k,v.to_p]}
      $cf[o] = cf_raw
    end
  end
  
  # Get the field-level term vector for given document
  def get_doc_field_vector(dno)
    return $dfv[dno] if $dfv[dno]
    dno = to_dno(dno) if dno.class == String
    return nil if !dno
    begin
      dv = get_index_info("dv", dno).split(/--- .*? ---\n/)    
      # Get the range of each field
      fields = dv[1].split("\n").find_all{|l|!l.include?("document ")}.
        map_hash{|l|e = l.split(" ") ; [(e[1].to_i...e[2].to_i) , e[0]]}
      #return nil if fields.values.size !=  fields.values.uniq.size
      $dfv[dno] = dv[2].split("\n").map{|l|l.split(" ")}.
        group_by{|e|f = fields.find{|k,v|k === e[0].to_i} ; (f)? f[1] : nil }.
        map_hash{|k,v|[k, v.map{|e|e[2]}]}      
    rescue Exception => e
      p dv
      nil
    end
  end
  
  
  def get_doc_lm(dno)
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)
    words = dv[2].split("\n").map{|l|l.split(" ")}.map{|e|e[2]}
    get_unigram_lm(words)
  end
  
  def get_doc_field_lm(dno, n = 1)
    #return $dflm[dno] if $dflm[dno]
    results = {}
    field_terms = get_doc_field_vector(dno)
    #return results if !field_terms
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
  
  def get_doc_field_length(dno)
    results = {}
    field_terms = get_doc_field_vector(dno)
    field_terms.map_hash{|k,v|[ k , v.size ]}
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
  
  def annotate_text_with_query(text, query)
    return text if !query
    query_s = query.scan(/\w+/).map_hash_with_index{|qw,i|[kstem(qw), i]}
    text.gsub("<","&lt;").gsub(">","&gt;").scan(/\W+|\w+/).map_with_index{|token, j|
      word = token.scan(/\w+/)[0]
      if word && (n_qw = query_s[kstem(word)])
          "<font color = 'white' style='background-color:#{$bgcolors[n_qw % 15]};'>[#{n_qw}] #{token}</font>"
      else
        token
      end
    }.join("").gsub("\n", "<br>\n")
  end
  
  def get_rel_flms( file_qrel, n = 1 )
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      get_doc_field_lm(l.split(" ")[2], n)
    end
  end
  
  
  # Get the list and LM of relevant docs from TREC QRel
  def get_rel_flms_multi( file_qrel, n = 1 )
    $dflms_rl = IO.read( to_path(file_qrel) ).split("\n").map{|l|
      e = l.split(" ")
      [e[0].to_i, get_doc_field_lm(e[2], 1)[1], e[3].to_f]
    }.find_all{|e|e[1].size > 0 && e[2] > 0}
    results = $dflms_rl.group_by{|e|e[0]}.map_hash do |qid,flms|
      rflm = if flms.size == 1
        flms[0][1]
      else
        #puts "Merging flms : \n #{flms.inspect}"
        rflm_t = flms[0][1]
        flms[1..-1].each do |flm|
          rflm_t = rflm_t.map_hash{|k,v| [k, v.sum_prob(flm[1][k] || {})]}
        end
        rflm_t
      end#if
      [qid, rflm]
    end#group_by
    results.sort_by{|k,v|k}.map{|e|e[1]}
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
        $dflms_rs << [d.qid, dflm, nscores[i]]
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
  
  # Get FLM from top K result documents
  def get_res_lm( res_docs)
    max_score = res_docs[0].score
    nscores = res_docs.map{|e|e.score - max_score}.map{|e|Math.exp(e)}
    result_n = nil
    res_docs.each_with_index do |d,i|
      #p d.did
      dlm = get_doc_lm(to_dno(d.did))
      $dlms_rs << [d.qid, dlm, nscores[i]]
      #p dlm.keys
      if !result_n
        result_n = dlm
      else
        result_n = result_n.sum_prob(dlm.map_hash{|k2,v2|[k2, v2 * nscores[i]]})
      end
    end
    result_n
  end
  
end