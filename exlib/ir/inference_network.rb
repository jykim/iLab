module InferenceNetwork
  include Math
  PTN_OP = /\#(wsum|combine)/
  PTN_NODE = /([\d\.]+?) (#{LanguageModel::PTN_TERM})\.\((\w+)\)/
  def self.eval_indri_query(query)
    #debugger
    result = query.strip.gsub(PTN_OP,',op_\1').
      gsub(PTN_NODE,'[\1,node_ql(\'\2\',d.flm[\'\3\'])],').gsub(/\s/,"").gsub(/\,\)/,")").gsub(/\(\,/,"(").gsub(/^\,/,"")
    #debug "[eval_indri_query] result = #{result}"
    module_eval <<END
          def score_doc(d)
            #puts "[score_doc] evaluating " + d.did
            result = #{result}
            #puts "Match Found!" if @match_found
            @match_found ? result : nil
          end
END
  end
  
  def set_rule(rule)
    #debugger
    rule_parsed = rule.split(",").map_hash{|e|e.split(":")}
    rule_name = rule_parsed['method']
    rule_value = case rule_name
    when 'jm' : rule_parsed['lambda']
    when 'dirichlet' : rule_parsed['mu']
    end
    @rule_name, @rule_value = rule_name, rule_value.to_f
    @lambda = case @rule_name
    when 'jm' : @rule_value
    #when 'dirichlet' : @rule_value / (@rule_value + dlm.size)
    end
  end
  
  def node_ql(qw, dlm ,o={})
    qw = (@qw[qw] ||= qw.downcase.stem)
    @match_found = true if dlm.f[qw]
    #debugger
    return 0 if dlm.size == 0
    debug "[score_ql] #{qw} #{(dlm.f[qw]||0)}* #{(1-@lambda)} / #{dlm.size} + #{(@col.lm.f[qw]||0)} * #{@lambda} / #{@col.lm.size}" if @debug
    cql = (@cql[qw] ||= ((@col.lm.f[qw]||0) * @lambda / @col.lm.size))
    (dlm.f[qw]||0) * (1.0-@lambda) / dlm.size + cql
  end
  
  # args = [[weight1,score1], [weight2,score2], ...]
  def op_wsum(*args)
    debug "#wsum(#{args.map{|e|e.join('*')}.join(' ')})" if @debug
    sum_weights = args.map{|e|e[0]}.sum
    args.map{|e|e[0] * e[1] / sum_weights}.sum
  end
  
  # args = [score1, score2, ...]
  def op_combine(*args)
    debug "#combine(#{args.join(" ")})" if @debug
    args.map{|e|log(e)}.sum / args.size
  end
end