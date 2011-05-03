module CalcMapProb
  MP_MIN = 0.0001
  # Get Mapping Prob. for given query
  # result = [[qw1,[[f1,mp1],[f2,mp2]]], [qw2,...]]
  def get_map_prob(query, o={})
    return query if query.scan(/\(/).size > 0
    mps = [] ; col_scores = {}
    qw_prev = []
    fields = o[:prm_fields] || $fields
    flm = o[:flm] || get_col_freq((o[:df]) ? {:df=>true,:prob=>true} : {:prob=>true})
    #puts "[get_map_prob] flm = #{o[:flm]}" if o[:flm]
    query.split(" ").each_with_index do |qw,i|
      #puts "[get_map_prob] Working on #{qw}"
      qw_prev << qw_s =  get_stem(qw, o)
      if o[:bgram] && qw_prev.size > 1
        qw = query.split(" ")[(i-1)..i].join(" ")
        qw_s = [qw_prev[-2], qw_s].join("_")
        #puts "[get_map_prob] bgram: #{qw_s}"
      elsif o[:bgram]
        next
      end
      weights = flm.map_hash{|k,v|[k,v[qw_s]] if v[qw_s] && fields.include?(k)}
      mp = weights.map_hash{|e|v=e[1]/weights.values.sum ; [e[0],((v >= MP_MIN)? v : MP_MIN)]}
      if mp.size == 0
        #error "[get_map_prob] Query-term [#{qw}->#{qw_s}] not found!"
      elsif o[:mp_all_fields]
        mp = fields.map_hash{|f|[f, ((mp[f])? mp[f] : MP_MIN )]}
      end
      mps << [qw , mp]
    end
    mhash2arr mps
  end
  
  def get_stem(qw, o)
    case (o[:stemmer] || $stemmer)
    when 'krovetz' : kstem(qw)
    when 'porter' : pstem(qw)
    else
      qw.downcase
    end
  end
  
  # Estimate MP based on the mixture of prob. distributions
  def get_mixture_map_prob(query, flms, types, weights, o = {})
    fields = o[:prm_fields] || $fields
    mps = [] ; prev_qw = nil
    query.split(" ").map_with_index do |qw,i|
      mp_flms = []
      flms.each_with_index do |flm, j|
        #debugger
        if types[j] == :prior
          mp_flms << [[qw, fields.map_with_index{|f,k|[ f, flm[k] ]}]]
        elsif types[j] == :cug || types[j] == :rug
          mp_flms << get_map_prob(qw, :flm => flm)
        elsif types[j] == :cbg || types[j] == :rbg
          mp_flms << get_map_prob([(prev_qw || ""),qw].join(" "), :flm => flm, :bgram=>true) #if prev_qw
        end
      end
      prev_qw = qw
      if mp_flms.flatten.uniq.size == 0
        #error "[get_mixture_map_prob] no mp found!"
        next
      else
        mp_flms = mp_flms.map{|e|e[0] ? e[0][1].to_h : {}}
      end
      fields.map_hash{|f| info [qw, f, mp_flms.map_with_index{|mp,j|(mp[f] || 0.0).r3 } ].flatten.join("\t") } if $o[:verbose]
      #File.open("MP_#{}.log",'a'){|f|f.puts }
      mps << [qw, fields.map_hash{|f| [f, mp_flms.map_with_index{|mp,j|(mp[f] || 0) * weights[j]}.sum ]}]
    end
   mhash2arr mps
  end
  
  def get_mixture_mpset(queries, types, weights, o = {})
    queries.map_with_index do |q,i|
      info ["QWord","Field",types,"=== #{i}th : #{q} ==="].flatten.join("\t") if $o[:verbose]
      flms = []
      types.each_with_index do |type, j|
        case type
        when :prior : flms << $hlm_weight
        when :cug   : flms << get_col_freq(:prob=>true)
        when :cbg   : flms << get_col_freq(:bgram=>true)
        when :rug   : flms << $rsflms[i][1].map_hash{|k,v|[k,v.to_p]}
        when :rbg   : flms << $rsflms[i][2].map_hash{|k,v|[k,v.to_p]}
        end
      end
      get_mixture_map_prob(q, flms, types , weights, o )
    end
  end
  
  # Get the KL-divrgence between two MP sets
  # 
  def get_mpset_klds( mpset1, mpset2  )
    return error "Length not equal!" if mpset1.size != mpset2.size
    mpset1.map_with_index{|mps,i| 
      begin
        mps.map_with_index{|mp,j|
          mp[1].kld_s(mpset2[i][j][1].to_p)}.sum
      rescue Exception => e
        error "[get_mpset_klds] error in #{i}th query : #{$queries[i]} \n#{mps[i].inspect}-#{mpset2[i].inspect} #{e.inspect}"
        0
      end      
      }
  end
  
  # Get the KL-divrgence between two MP sets
  # 
  def get_mpset_prec( mpset1, mpset2  )
    return error "Length not equal!" if mpset1.size != mpset2.size
    mpset1.map_with_index{|mps,i| 
      begin
        mps.map_with_index{|mp,j|
          (mp[1].max_pair[0] == mpset2[i][j][1].max_pair[0])? 1 : 0 }.sum.to_f / mps.size
      rescue Exception => e
        error "[get_mpset_klds] error in #{i}th query : #{$queries[i]} \n#{mps[i].inspect}-#{mpset2[i].inspect} #{e.inspect}"
        0.0
      end
      }
  end
  
  # Turn Hash form of MP to Array
  def mhash2arr(mps)
    mps.map{|e|[e[0], e[1].to_p.find_all{|term,prob|prob > 0}.sort_val]}.find_all{|mp|mp[1].size>0}
  end
  
  # Turn Array form of MP to Hash
  def marr2hash(mps)
    mps.map{|e|[e[0], e[1].to_h]}
  end
  
  # Get MPs estimated from collection FLMs
  def get_mpset( queries, o = {} )
    #debugger #puts "[get_mpset] #{q}" ;  
    queries.map{|q| marr2hash get_map_prob(q, o)}
  end
  
  # Get MPs estimated from a set of FLMs
  def get_mpset_from_flms( queries, flms, o = {} )
    flms.map_with_index{|e,i|marr2hash get_map_prob(queries[i], o.merge(:flm=>e))}
  end
end
