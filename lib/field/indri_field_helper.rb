module IndriFieldHelper
  #Collection Frequency
  # o[:prob] : return probability instead
  # return : {'FIELD1'=>{term1=>prob1,...},... }
  def get_col_freq(o = {})
    cf_fn = "FREQ_#{File.basename(@index_path)}.in"
    if !File.exist?(to_path(cf_fn)) #|| $o[:redo]
      calc_col_freq( to_path(cf_fn))
      puts "[get_col_freq] Creating #{cf_fn}..."
    end
    if !@cf[o.to_s]
      cf_raw = IO.read(to_path(cf_fn)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      puts "[get_col_freq] Fields read : #{cf_raw.keys.inspect}"
      @cf[o.to_s] = ((o[:prob])? cf_raw.map_hash{|k,v|[k,v.to_p]} : cf_raw)
    else
      @cf[o.to_s]
    end
  end

  def calc_col_freq(filename , o={})
    info "calc_col_freq for #{filename}"
    cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp #@index_path #{filename}", :mode=>'a')
    `#{cmd}`
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
  def get_rdocs( file_qrel )
    IO.read( to_path(file_qrel) ).split("\n").map do |l|
      dno = to_dno(l.split(" ")[2])
      {:dno=>dno, :flm=>get_doc_field_lm(dno)}
    end
  end
  
  def get_doc_lm(dno)
    dv = get_index_info("dv", dno).split(/--- .*? ---\n/)
    dv[2].split("\n").map{|l|l.split(" ")}.find_all{|e|e[2]!="[OOV]"}.map{|e|e[2]}.to_pdist
  end
end