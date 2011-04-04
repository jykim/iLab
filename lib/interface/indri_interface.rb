# Interface for Indri Search Engine
$indri_path = ENV['INDRI']
DEF_LAMBDA = 0.1
DEF_MU = 1500

class IndriInterface
  DEF_SMOOTHING = ['method:dirichlet,mu:1500,operator:term','method:dirichlet,mu:4000,operator:window']
  attr_accessor :index_path, :title_field , :cf
  include ILabHelper , OptionHandler, Math
  include IndriFieldHelper, GenHelper, PRMHelper, PRMMulticolHelper
  
  def initialize(name = "" , o={})
    @name = name
    @cf = {}
    @index_path = o[:index_path] || $index_path
    @title_field = o[:title_field] || $title_field #The field that denotes document title
    # @index_path = [@index_path] if @index_path.class == String 
  end
  
  # Query Builder
  # - requires template file in "template_#{o[:template].to_s}.rhtml"
  # - assign query-likelyhood template as default
  def build_query(topics , exp , o={})
    query_offset = o[:offset] || 1
    o[:template] = :ql if !o[:template]
    o[:lambda] = o[:lambda] || DEF_LAMBDA
    #err("[build_query] HLM weight not specified!") if o[:template] == :hlm && !o[:hlm_weights]
    working_set = o[:working_set] || []
    prior_clause = (o[:prior])? "#prior(#{o[:prior]}) " :""
    smoothing_rule = [o[:smoothing]].flatten || DEF_SMOOTHING
    template = ERB.new(IO.read( to_path("query_#{o[:template].to_s}.rhtml")))
    #$o_tmp = o # For accessibility in template(.rhtml) FIXME - any neater way?
    fwrite(exp+'.qry' , template.result(binding))
  end
  
  # Build index 
  # - corpus [{:path=> , :class=>}]
  def build_index(name , src_docs , dest_path , o={})
    `mkdir -p #{dest_path}` if !File.exist?(dest_path)
    src_docs = (src_docs.class == String)? [src_docs] : src_docs
    o[:template] = :indri if !o[:template] #assign default template
    o[:template] = to_path("index_#{o[:template].to_s}.rhtml") if o[:template].class == Symbol
    template = ERB.new(IO.read(o[:template]))
    fwrite("index_#{name}.xml" , template.result(binding))
    `#{$indri_path}/bin/buildindex #{to_path("index_#{name}.xml")}`
  end
  
  # Run query
  # - :remote_query : submit query to the cluster using qsub
  def run_query(query_file , exp , o = {})
    indri_path = o[:indri_path] || $indri_path
    if o[:remote_query]
      cmd = fwrite('cmd_run_query_remote.log' , "qsub -sync y #{$ilab_root}/script/sydney_runquery.sh \
      #{indri_path} #{to_path(query_file)} #{to_path(exp+'.res')} #{o[:param_query]}" , :mode=>'a')
      `#{cmd}`
    else
      cmd = fwrite('cmd_run_query.log' , "#{indri_path}/bin/runquery #{o[:param_query]} \
      #{to_path(query_file)} |grep -e ^[0-9] > #{to_path(exp+'.res')}" , :mode=>'a')
      `#{cmd}` #result = fwrite(exp+'.res'   , `#{cmd}`){|e| e =~ /^[0-9]/}
      filter_result_file(to_path(exp+'.res'))
    end
  end
  
  def get_index_info(job , arg = "")
    cmd = fwrite('cmd_dump_index.log' , "#$indri_path/bin/dumpindex #@index_path #{job} #{arg}" , :mode=>'a')
    `#{cmd}`
  end
  
  def to_did(dno)
    get_index_info( 'dn', "#{dno}")    
  end
  
  def to_dno(did)
    #puts "[to_dno] did=#{did}"
    get_index_info( 'di', "docno #{did}").to_i
  end
  
  def get_col_stat()
    s = get_index_info("s")
    r = s.split("\n").map{|l|l.split(/\s+/)}
    {:doc_no=>r[1][1].to_i}
  end
  
  def get_df()
    return $dfh if $dfh
    s = get_index_info("v")
    $dfh = s.split("\n").map{|l|l.split(/\s+/)}.map_hash{|e|[e[0],e[2].to_i]}
  end
  
  def get_term_info(term)
    s = get_index_info("t", term)
    s.split("\n").map{|l|l.split(/\s+/)}
  end
  
  def run_make_prior(type = 'length')
    filepath_prior = to_path( "#{@name}_#{type}.prior" )
    return if type =~ /^length/ && fcheck(filepath_prior)
    cmd = fwrite('cmd_prior_calc.log' , "#$indri_path/bin/priorcalc #@index_path #{filepath_prior} #{type}" , :mode=>'a') if !fcheck(filepath_prior)
    `#{cmd}`
    cmd = fwrite('cmd_make_prior.log' , "#$indri_path/bin/makeprior -index=#@index_path -input=#{filepath_prior} -name=#{type}" , :mode=>'a')
    `#{cmd}`
    puts "#{filepath_prior} was created & installed..."
  end
  
  #Filter prior file so that only documents in the index are left
  # - renormalize probability
  def filter_prior( filename , docs_filename)
    docs = dsvread(docs_filename).map_hash{|l|[l[1], 0]}
    a = dsvread(filename).find_all{|l|docs[l[0]]}
    sum = a.sum{|l|Math.exp(l[1].to_f)}
    a.map{|l|[l[0], Math.log(Math.exp(l[1])/sum)]}
    fbkup(filename) ; dsvwrite(filename, a)
  end
  
  #Get Smoothing Parameter
  def self.get_sparam(method, param_value , field = nil, operator = 'term')
    param_name = case method
    when 'dirichlet' : 'mu'
    when 'jm' : 'lambda'
    when 'bm25' : 'bf'
    end
    field_name = (field)? ",field:#{field}" : ""
    "method:#{method},#{param_name}:#{param_value},operator:#{operator}#{field_name}"
  end
  
  #Get Smoothing Parameter
  # - accept hash {param_key=>param_value,...} as parameter
  def self.get_sparam2(method, param_hash , field = nil, operator = 'term')
    param_str = param_hash.map{|k,v|[k,v].join(":")}.join(",")
    s_operator = (operator)? ",operator:#{operator}" : ""
    s_field = (field)? ",field:#{field}" : ""
    "method:#{method},#{param_str}#{s_operator}#{s_field}"
  end
  
  # Field-level Smoothing Parameter
  # fix param_value
  def self.get_field_sparam(xvals , yvals, param_value, type = 'dir')
    xvals.map_with_index do |f,i| 
      case type
      when 'dir' : get_sparam2('dir', {"mu"=>param_value, "documentMu"=>yvals[i]}, f)
      when 'jm'  : get_sparam2('jm',  {"lambda"=>param_value, "documentLambda"=>yvals[i]}, f)
      end
    end
  end
  
  # Field-level bf(BM25F) Parameter
  def self.get_field_bparam(xvals , yvals, k1 = 1.0)
    xvals.map_with_index{|f,i| get_sparam2('bf1',  {"bf"=>yvals[i]}, f, nil)}  << "node:wsum,method:bf2,k1:#{$k1}"
  end
  
  # Field-level bf(BM25) Parameter
  def self.get_field_bparam2(xvals , yvals, k1 = 1.0)
    xvals.map_with_index{|f,i| get_sparam2('bm25',  {"bf"=>yvals[i]}, f, nil)}  << "node:wsum,method:bm25,k1:#{$k1}"
  end
  
  #[1,2,3] => #(1 2) #(2 3) 
  def get_combination(str , prefix)
    tokens = str.split ; result = ""
    return str if tokens.size == 1
    0.upto(tokens.size-2) do |i|
      result += "##{prefix}(#{tokens[i..i+1].join(' ')}) "
    end
    result
  end
  
  # Apply Krovetz Stemming
  def kstem(str)
    $kstem = {} if !defined?($kstem)
    #return str[0..2] if ['january','february','march','april','june','july','august','september','october','november','december'].include?(str.downcase)
    $kstem[str] = $kstem[str] || `#{$indri_path}/bin/kstem #{str}`.strip#.downcase
  end
  
  def init_kstem(file)
    puts "[init_kstem] using #{to_path("#{file}.stem")}"
    $stemmer = 'krovetz'
    $kstem = {} if !defined?($kstem)
    File.open(to_path("#{file}.stem"),"w"){|f| 
      f.puts IO.read(to_path(file)).scan(/[A-Za-z0-9]+/).uniq.join("\n")}
    result = `#$indri_path/bin/kstem #{to_path("#{file}.stem")}`
    result.split("\n").map{|e| s = e.split("\t") ; $kstem[s[0]] = s[1] }
  end
  
  # Apply porter stemmer
  def pstem(str)
    Lingua.stemmer(str.downcase)
  end
  
  # Calc Pointwise Mutual Information
  def calc_mi(t1, t2)
    v = `#{$lemur_path}/bin/calc_mi #{$lemur_path}/bin/param #@index_path #{t1} #{t2}`.split("\n").last.to_f
    (v > 0)? Math.log(v) : 0
  end
  
  # - Options
  #  - :freq : calculate frequency instead of probability
  #  - :whole_doc : calculate the value for whole document intead of each field
  #def calc_col_freq(filename , o={})
  #  o[:freq] = true #always calculate freq. in Indri
  #  info "calc_col_freq for #{filename}"
  #  cmd = fwrite('cmd_calc_mp.log' , "#{$indri_path}/bin/calc_mp#{(o[:whole_doc])? "_doc" : ""}#{(o[:freq])? "_freq" : ""} #{$lemur_path}/bin/param #@index_path #{filename}", :mode=>'a')
  #  `#{cmd}`
  #end
end


#Get Smoothing Parameter
def get_sparam(method, param_value , field = nil, operator = 'term')
  IndriInterface.get_sparam(method, param_value , field, operator)
end

#Get Smoothing Parameter
def get_sparam2(method, param_hash , field = nil, operator = 'term')
  IndriInterface.get_sparam2(method, param_hash , field, operator)
end
