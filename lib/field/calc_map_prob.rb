module CalcMapProb
  MP_MIN = 0.0001
  # Get Mapping Prob. for given query
  # result = [[qw1,[[f1,mp1],[f2,mp2]]], [qw2,...]]
  def get_map_prob(query, o={})
    return query if query.scan(/\(/).size > 0
    mps = [] ; col_scores = {}
    fields = o[:prm_fields] || $fields
    flm = o[:flm] || get_col_freq((o[:df]) ? {:df=>true,:prob=>true} : {:prob=>true})
    #puts "[get_map_prob] flm = #{o[:flm]}" if o[:flm]
    query.split(" ").each_with_index do |qw,i|
      #puts "[get_map_prob] Working on #{qw}"
      #Read Collection Stat.
      qw_s = case (o[:stemmer] || $stemmer)
      when 'krovetz' : kstem(qw)
      when 'porter' : pstem(qw)
      else
        qw.downcase
      end
      weights = flm.map_hash{|k,v|[k,v[qw_s]] if v[qw_s] && fields.include?(k)}
      mp = weights.map_hash{|e|v=e[1]/weights.values.sum ; [e[0],((v >= MP_MIN)? v : MP_MIN)]}
      #if mp.size == 0
      #  error "[get_map_prob] Query-term [#{qw}->#{qw_s}] not found!"
      #elsif o[:mp_all_fields]
      #  mp = fields.map_hash{|f|[f, ((mp[f])? mp[f] : MP_MIN )]}
      #end
      #o[:fix_mp_for].map{|k,v|mp[k] = v} if o[:fix_mp_for]
      mps << [qw , mp]
    end
    mhash2arr mps
  end
  
  # Estimate MP based on the mixture of prob. distributions
  def get_mixture_map_prob(query, flms, weights, o = {})
    fields = o[:prm_fields] || $fields
    mps = [] ; prev_qw = nil
    query.split(" ").map_with_index do |qw,i|
      # Get MP estimate for each FLMs
      mp_flms = flms[0..-3].map{|flm| get_map_prob(qw, :flm => flm)}
      # Second Last flm is based on Prior
      if o[:prior]
        mp_flms << [[qw, fields.map_with_index{|f,j|[ f, o[:prior][j] ]}]]
      end
      # Last flm is based on Bigram 
      if prev_qw
        mp_flms << get_map_prob([prev_qw,qw].join("_"), :flm => flms[-2]) 
        mp_flms << get_map_prob([prev_qw,qw].join("_"), :flm => flms[-1]) 
      end
      prev_qw = qw
      if mp_flms.flatten.uniq.size == 0
        error "[get_mixture_map_prob] no mp found!"
        next
      else
        mp_flms = mp_flms.map{|e|e[0] ? e[0][1].to_h : {}}
      end
      #fields.map_hash{|f| info [qw, f, mp_flms.map_with_index{|mp,j|(mp[f] || 0.0).r3 } ].flatten.join("\t") } if $o[:verbose]
      #File.open("MP_#{}.log",'a'){|f|f.puts }
      mps << [qw, fields.map_hash{|f| [f, mp_flms.map_with_index{|mp,j|(mp[f] || 0) * weights[j]}.sum ]}]
    end
   mhash2arr mps
  end
  
  def get_mixture_mpset(queries, weights, o = {})
    queries.map_with_index do |q,i|
      #info ["QWord","Field","cUg","rUg","Prior","cBg","rBg","=== #{i}th : #{q} ==="].join("\t") if $o[:verbose]
      get_mixture_map_prob(q, [get_col_freq(), $rsflms[i][1], get_col_freq(:bgram=>true), $rsflms[i][2]], weights, o )
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
