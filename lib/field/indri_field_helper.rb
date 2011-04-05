module IndriFieldHelper
  #Collection Frequency
  # o[:prob] : return probability instead
  # return : {'FIELD1'=>{term1=>prob1,...},... }
  def get_col_freq(o = {})
    cf_fn = "FREQ_#{File.basename(@index_path)}.in"
    df_fn = "DOC_FREQ_#{File.basename(@index_path)}.in"
    bgram_fn = "BGRAM_FREQ_#{File.basename(@index_path)}.in"
    if !File.exist?(to_path(cf_fn)) #|| !File.exist?(to_path(df_fn)) || !File.exist?(to_path(bgram_fn))
      cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{to_path(cf_fn)}", :mode=>'a')
      #cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{to_path(cf_fn)} #{to_path(df_fn)} #{to_path(bgram_fn)}", :mode=>'a')
      `#{cmd}`
    end
    parse_col_freq(cf_fn)
    #parse_col_freq(df_fn, :df=>true)
    #parse_col_freq(bgram_fn, :bgram=>true)
    @cf[o.to_s]
  end
  
  def parse_col_freq(filename, o = {})
    if !@cf[o.to_s]
      cf_raw = IO.read(to_path(filename)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      puts "[parse_col_freq] reading #{filename} (#{o.inspect})..."
      #puts "[parse_col_freq] Fields read : #{cf_raw.keys.inspect}"
      @cf[o.to_s] = cf_raw
    end
  end
  
  def get_doc_field_lm(dno)
    dno = to_dno(dno) if dno.class == String
    return nil if !dno
    #info "[get_doc_field_lm] dno = #{dno}"
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)
    fields = dv[1].split("\n").find_all{|l|!l.include?("document ")}.map_hash{|l|e = l.split(" ") ; [(e[1].to_i...e[2].to_i) , e[0]]}
    #return nil if fields.values.size !=  fields.values.uniq.size
    dv[2].split("\n").map{|l|l.split(" ")}.
      group_by{|e|f = fields.find{|k,v|k === e[0].to_i} ; (f)? f[1] : nil }. #FIXME Support overlapping elements
      map_hash{|k,v|[k,v.find_all{|e|e[2]!="[OOV]"}.map{|e|e[2]}.to_pdist]}    
  end
  
  # Get the list and LM of relevant docs from TREC QRel
  def get_rel_flms( file_qrel )
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      get_doc_field_lm(l.split(" ")[2])
    end
  end
  
  # Get FLM from top K result documents
  def get_res_flm( res_docs )
    max_score = res_docs[0].score
    result = nil
    nscores = res_docs.map{|e|e.score - max_score}.map{|e|Math.exp(e)}
    res_docs.each_with_index do |d,i|
      dflm = get_doc_field_lm(d.did)
      if !result
        result = dflm
      else
        result = result.map_hash{|k,v|
          dflm[k] = {} if !dflm[k]
          [k,v.sum_prob(dflm[k].map_hash{|k2,v2|[k2, v2*nscores[i]]})]}
      end
    end
    result
  end
  
  def get_doc_lm(dno)
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)
    dv[2].split("\n").map{|l|l.split(" ")}.find_all{|e|e[2]!="[OOV]"}.map{|e|e[2]}.to_pdist
  end
end