module FieldHelper
  #Collection Frequency
  # o[:prob] : return probability instead
  # return : {'FIELD1'=>{term1=>prob1,...},... }
  def get_col_freq(o = {})
    cf_fn = "FREQ_#{File.basename(@index_path)}_#{o[:whole_doc]}.in"
    if !File.exist?(to_path(cf_fn))
      calc_col_freq( to_path(cf_fn), :whole_doc=>o[:whole_doc])
      puts "[get_col_freq] Creating #{cf_fn}..."
    end
    if !@cf[o.to_s]
      cf_raw = IO.read(to_path(cf_fn)).split("\n").
        map_hash{|l|la = l.split("\t");[la[0], la[1..-1].map_hash{|e|a = e.split ; [a[0] , a[1].to_f]}]}
      @cf[o.to_s] = ((o[:prob])? cf_raw.map_hash{|k,v|[k,v.to_p]} : cf_raw)
    else
      @cf[o.to_s]
    end
  end
end