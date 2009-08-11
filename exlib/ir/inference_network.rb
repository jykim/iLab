module IR
  module InferenceNetwork
    include Math
    PTN_OP = /\#(wsum|combine)/
    PTN_NODE = /([\d\.]+?) (#{LanguageModel::PTN_TERM})\.\((\w+)\)/
    def self.eval_indri_query(query)
      result = query.gsub(PTN_OP,'op_\1').
        gsub(PTN_NODE,'[\1,node_ql(\'\2\',d.flm[\'\3\'])]').gsub(/ /," , ")
      debug "[eval_indri_query] result = #{result}"
      module_eval <<END
            def score_doc(d)
              #puts "[score_doc] evaluating " + d.did
              #{result}
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
    end
    
    def node_ql(qw, dlm ,o={})
      lambda = case @rule_name
      when 'jm' : @rule_value
      when 'dirichlet' : @rule_value / (@rule_value + dlm.size)
      end
      #debugger
      #debug "[score_ql] #{(dlm.p[qw]||0)}* #{(1-lambda)} + #{(clm.p[qw]||0)} * #{lambda}"
      (dlm.p[qw]||0)* (1-lambda) + (@col.lm.p[qw]||0) * lambda
    end
    
    # args = [[weight1,score1], [weight2,score2], ...]
    def op_wsum(*args)
      #debug "#wsum(#{args.map{|e|e.join('*')}.join(' ')})"
      sum_weights = args.map{|e|e[0]}.sum
      args.map{|e|e[0] * e[1] / sum_weights}.sum
    end
    
    # args = [score1, score2, ...]
    def op_combine(*args)
      #debug "#combine(#{args.join(" ")})"
      args.map{|e|log(e)}.sum / args.size
    end
  end
end