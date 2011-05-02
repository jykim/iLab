module GenQuery  
  # Build known-item topic
  # o[:queries] : [[dno1, query1], [dno2, query2], ...]
  def build_knownitem_topics(file_topic, file_qrel, o={})
    queries = [] #o[:queries] 
    #results = []
    o[:topic_no] ||= 50
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
      clm = get_col_freq(:whole_doc=>true)
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
