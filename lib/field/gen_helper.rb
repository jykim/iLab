module GenHelper
  # Generate document with metadata from the collection
  # @param String doc_id
  # @param Array fields : {:tag=>, :content=>}
  def generate_doc(path, doc_id, fields , o = {})
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    File.open("#{path}/#{doc_id}.xml", "w"){|f| f.puts template.result(binding)}
    puts "[gen_doc] #{doc_id} file created"
  end
  
  # Get term distribution 
  def get_tdist(prefix, term_no)
    (1..term_no).to_a.map_hash{|i|[prefix+i.to_s, 1.0/i]}
  end
  
  # Generate Collection Documents
  def build_collection(col_id, doc_no, field_no, mix_ratio = 0.5, term_no = 20, field_size = 10, doc_size = 200)
    clm = get_tdist("c", term_no)
    flms = (1..field_no).to_a.map_hash{|i| ["f#{i}", get_tdist(i.to_s+"f", term_no).smooth(mix_ratio, clm)] }
    fsizes = flms.map_hash{|k,v|[k,field_size]}
    flms["clm"], fsizes["clm"] = clm, doc_size - field_size * field_no
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    #p flms

    File.open(to_path("#{col_id}.trecweb"),"w") do |f|
      1.upto(doc_no) do |i|
        doc_id = "D#{i}"
        fields = flms.map{|k,v|{:tag=>k, :content=>v.to_p.sample_pdist(fsizes[k]).join(" ")}}
        f.puts template.result(binding)
      end
    end
  end
  
  # Build known-item topic
  # o[:queries] : [[dno1, query1], [dno2, query2], ...]
  def build_knownitem_topics(file_topic, file_qrel, o={})
    queries = [] #o[:queries] 
    o[:topic_no] ||= 50
    results = []
    doc_no = get_col_stat()[:doc_no]
    if o[:topic_prior]
      filepath_prior = "#{$col}_#{o[:topic_prior]}.prior"
      if !fcheck(filepath_prior)
        err "[build_knownitem_topics] No prior found! (#{filepath_prior})"
        return
      end
      o[:dids] = []
      $topic_docs = dsvread(filepath_prior).map{|l|[l[0],Math.exp(l[1])]}
      0.upto(o[:topic_no]-1){|i| o[:dids][i] = $topic_docs.dice}
    end
    info "Total #{doc_no} / Chosen docs #{o[:dids].size}" if o[:dids]
    0.upto((o[:dids])? (o[:dids].size-1) : o[:topic_no]-1) do |i|    
      info "[build_knownitem_topics] did[#{i}] : #{o[:dids][i]}" if o[:dids]
      dno = (o[:dids])? to_dno(o[:dids][i]) : rand(doc_no)+1
      next unless dno > 0
      begin
        query = if o[:topic_type] =~ /^F_FF.*/
                  fields = $field_set[rand($field_set.size)]
                  get_knownitem_topic(dno, o[:topic_type], fields.size, o.merge(:doc_no=>doc_no,:fields=>fields))
                else
                  topic_len = o[:query_len] || 3#(o[:query_len])? o[:query_len] : $query_lens[rand($query_lens.size)]
                  get_knownitem_topic(dno, o[:topic_type], topic_len, o.merge(:doc_no=>doc_no))
                end
        raise DataError, "No content in query!" if query.join(" ").blank?
        results << get_doc_field_lm(dno) #{:dno=>dno, :flm=>get_doc_field_lm(dno)}
      rescue Exception => e
        warn "[build_knownitem_topics] Unable to process doc ##{dno} (#{e})"
        next
      end
      queries << [to_did(dno).strip, query.join(" ")]
    end
    write_topic(to_path(file_topic), queries.map{|e|{:title=>e[1]}})
    write_qrel(to_path(file_qrel), queries.map_hash_with_index{|e,i|[i+1,{e[0]=>1}]})
    return results
  end

  # Generate known-item topic given document and gen. method
  # - return P(term) if negativ length is given
  def get_knownitem_topic(dno, topic_type, len = -1, o={})
    dfh = get_df()
    topic = []
    info "[get_knownitem_topic] #{dno} #{topic_type}"
    case topic_type
    when /^D_/
      clm = get_col_freq(:whole_doc=>true)
      dlm = get_doc_lm(dno)
      info "DLM size : #{dlm.size}"
      dlm_s = case topic_type
              when "D_RN"   : dlm.map_hash{|k,v|[k,1.0/dlm.size]}
              when "D_TF"   : dlm
              when 'D_IDF'  : dlm.map_hash{|k,v|[k,Math.log(o[:doc_no]/dfh[k])]}.to_p
              when 'D_TIDF' : dlm.map_hash{|k,v|[k,v*Math.log(o[:doc_no]/dfh[k])]}.to_p
              end
      #p "dlm = #{dlm_s.sort_by{|k,v|v}.reverse.inspect}"
      return dlm_s if len < 0
      1.upto(len){|j|topic << dlm_s.dice}
      
    when /^F_/
      cflm = get_col_freq()
      dflm = get_doc_field_lm(dno)
      field_no = dflm.keys.size
      next if !dflm #|| dflm.keys.size != cflm.keys.size
      #assert_equal(dflm.keys.sort , cflm.keys.sort, 'DFLM != CFLM')
      dflm_s = case topic_type
               when /_RN$/   : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2,1.0/v.size]}]}
               when /_TF$/   : dflm
               when /_IDF$/  : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2, Math.log(o[:doc_no]/dfh[k2])]}.to_p]}
               when /_TIDF$/ : dflm.map_hash{|k,v|[k,v.map_hash{|k2,v2|[k2, v2*Math.log(o[:doc_no]/dfh[k2])]}.to_p]}
      end
      return dflm_s.values.merge_elements if len < 0
      1.upto(len) do |j|
        field = case topic_type
                when /^F_FF/ : o[:fields][j]
                when /^F_RN/ : dflm.keys[rand(field_no)]
                else
                  topic_type.scan(/^F_([A-Za-z]+?)_/)[0][0]
                end
        #puts "[get_knownitem_topic] field = #{field} (#{dflm_s.keys})"
        #p "dflm = #{dflm_s.map{|k,v|v.sort_by{|k,v|v}.reverse}.inspect}"
        #xp "field = #{field}"
        topic << dflm_s[field].dice() if dflm_s[field]
      end
    when /^EN_/
      dlm = get_doc_lm(dno)
      dent = dlm.keys.map do |w|
        mp = get_col_freq.map_hash{|k,v| [k,v[w]] if v[w] && $fields.include?(k)}
        [w, mp.values.h]
      end
      ent_list = dent.find_all{|e|e[1] > 0}.sort_by{|e|e[1]}
      
      1.upto(len) do |j|
        topic << case topic_type
        when /L$/ #Low entropy -> skewed MP distribution
          ent_list.to_h.inverse.dice()
        when /H$/
          ent_list.dice()
        end
      end
      #info "[get_knownitem_topic] ent_list: #{ent_list.inspect}"
    else
      raise ArgError, "[get_knownitem_topic] not a supported method! (#{topic_type})"
    end
    #0.upto(topic.size-1){|i| topic[i] = "QWERTYUIOP" if rand() <= (o[:noise_ratio] || 0.1)}
    info "[get_knownitem_topic] #{dno} | #{topic.join(" ")} | #{topic_type}"
    topic
  end
  
  # Get generation probability of given query and reldoc ID using given topic_type
  def get_gen_prob(query, dno, topic_type, o={})
    p_term = get_knownitem_topic(dno, topic_type, -1, o)
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
