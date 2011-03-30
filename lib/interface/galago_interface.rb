class GalagoInterface
  DEF_SMOOTHING = 'linear'
  include ILabHelper , OptionHandler, Math
  include FieldHelper, GenHelper, PRMHelper
  
  def initialize(name = "" , o={})
    @name = name
    @index_path = o[:index_path] || $index_path
    @title_field = o[:title_field] || $title_field #The field that denotes document title
    # @index_path = [@index_path] if @index_path.class == String 
  end
  
  def build_query(topics , exp , o={})
    query_offset = o[:offset] || 1
    o[:template] = :ql if !o[:template]
    
    smoothing = o[:smoothing] || DEF_SMOOTHING
    lambda = o[:lambda] || DEF_LAMBDA
    mu = o[:mu] || DEF_MU
    #err("[build_query] HLM weight not specified!") if o[:template] == :hlm && !o[:hlm_weights]
    #working_set = o[:working_set] || []
    #prior_clause = (o[:prior])? "#prior(#{o[:prior]}) " :""
    #smoothing_rule = [o[:smoothing]].flatten || DEF_SMOOTHING
    template = ERB.new(IO.read( to_path("gquery_#{o[:template].to_s}.rhtml")))
    #$o_tmp = o # For accessibility in template(.rhtml) FIXME - any neater way?
    fwrite(exp+'.qry' , template.result(binding))
  end
  
  def build_index(name, src_docs, dest_path, o={})
    #o[:template] = :galago if !o[:template] #assign default template
    #o[:template] = to_path("index_#{o[:template].to_s}.rhtml") if o[:template].class == Symbol
    #template = ERB.new(IO.read(o[:template]))
    #fwrite("index_#{name}.xml" , template.result(binding))
    #{}`#{$galago_path}/bin/galago build #{to_path("index_#{name}.xml")}`
    cmd = "#{$galago_path}/bin/galago build -stemming=#{o[:stemmer]||'porter'} #{dest_path} #{src_docs}"
    puts cmd
    `#{cmd}`
  end
  
  # Run query
  # - :remote_query : submit query to the cluster using qsub
  def run_query(query_file , exp , o = {})
    index_path = o[:index_path] || @index_path
    cmd = fwrite('cmd_galago_run_query.log' , "#{$galago_path}/bin/galago batch-search --index=#{index_path} #{o[:param_query]} \
    #{to_path(query_file)} |grep -e ^[0-9] > #{to_path(exp+'.res')}" , :mode=>'a')
    `#{cmd}`
  end
end