require 'erb'
require 'rubygems'
require 'ruby-debug'
require 'enumerator'
#if ENV['HOSTNAME'] =~ /^compute/
#  require 'external/gems/RedCloth-4.0.3/lib/redcloth'  
#else
  require 'redcloth'
#end
require 'test/unit'

require "logger"
require 'ilab_include'
require 'lib/gnuplot.rb'
require 'stemmer.rb'
include Test::Unit::Assertions

load 'extensions/extension.rb'
load 'extensions/probability.rb'
load 'extensions/statistics.rb'
load 'ilab_extension.rb'
load 'rails_extension.rb'
load 'ilab_loader.rb'
load 'ilab_helper.rb'
load 'ilab_globals.rb'
load 'ilab_exceptions.rb'

load 'lib/option_handler.rb'
load 'markup_handler.rb'
load 'lib/gnuplot_handler.rb'
load 'lib/stat_length.rb'
load 'lib/prm_helper.rb'

load 'interface/crf_interface.rb'
load 'interface/indri_interface.rb'
load 'interface/r_interface.rb'
load 'interface/yahoo_interface.rb'
load 'interface/lda_interface.rb'
load 'interface/cluster_interface.rb'

load 'object/document_set.rb'
load 'object/result_document_set.rb'
load 'object/relevant_document_set.rb'
load 'object/query_helper.rb'
load 'object/query.rb'
load 'object/query_set.rb'

load 'adhoc/pd_lib.rb'

$ilab_root ||= ENV['ILAB_ROOT']
RUBY_CMD = "/work1/jykim/app/ruby/bin/ruby -W0 -I #$ilab_root/lib -I #$ilab_root/ilab"
DEFAULT_ENGINE_TYPE = :indri

# ILab base class
class ILab
  include ApplicationFramework , OptionHandler
  include ILabHelper , StatLength , MarkupHandler
  include GnuplotHandler , RInterface
  attr_accessor :name, :engine
  attr_reader :rs , :qs , :rl , :ldist , :qsa , :rsa , :engine
  
  def initialize(exp_name = 'test', o = {})
    @name = exp_name
    @o = o
    $engine = case (o[:engine_type] || DEFAULT_ENGINE_TYPE)
              when :indri
                IndriInterface.new(@name , o)
              end
    clear
  end

  def clear
    @rs = {}
    @rsa = []
    @qs = {}
    @qsa = []
  end

  def to_s
    "[#@name] #{@qs.map{|k,v|k}.join(' ')}"
  end

  def inspect
    to_s
  end
  
  def config_path(o = {})
    $work_path = o[:work_path] || '.'
    if o[:index_path]
      $engine.index_path = o[:index_path]
    end
    Dir.mkdir( $work_path ) if !File.exist?( $work_path )
    Dir.mkdir( $work_path+"/query" ) if !File.exist?( $work_path+"/query" )
    Dir.mkdir( $work_path+"/log" ) if !File.exist?( $work_path+"/log" )
    Dir.mkdir( $work_path+"/in"  ) if !File.exist?( $work_path+"/in"  )
    Dir.mkdir( $work_path+"/out" ) if !File.exist?( $work_path+"/out" )
    Dir.mkdir( $work_path+"/doc" ) if !File.exist?( $work_path+"/doc" )
    Dir.mkdir( $work_path+"/tmp" ) if !File.exist?( $work_path+"/tmp" )
    Dir.mkdir( $work_path+"/dmp" ) if !File.exist?( $work_path+"/dmp" )
    Dir.mkdir( $work_path+"/data") if !File.exist?( $work_path+"/data" )
    Dir.mkdir( $work_path+"/plot") if !File.exist?( $work_path+"/plot" )
    Dir.mkdir( $work_path+"/rpt") if !File.exist?( $work_path+"/rpt" )
    init_logger("#{get_expid_from_env()}.log" , :path=>$work_path+"/log")
  end

  def crt_add_result_set(file , set_name , o = {}, &filter)
    @rsa << @rs[set_name] = create_result_set(file , set_name , o, &filter)
    @rs[set_name]
  end

  def add_result_set(result_set)
    @rsa << @rs[result_set.name] = result_set
    result_set
  end
  
  # Read DocumentSet from result set file
  # format : 701 Q0 GX056-52-13602466 1 -3.66607 indri
  # - filter : fetch only a subset of docs
  #  - e.g. {|d|d.query == 701} : only documents from query 701
  def create_result_set(file , set_name , o = {}, &filter)
    ds = ResultDocumentSet.new( set_name , o )
    dsvread(file).each do |l|
      d_tmp = ResultDocument.new( l[2] , :qid => l[0].to_i , :rank => l[3].to_i , :score => l[4].to_f, :remark => l[5] )
      ds.add_doc d_tmp if (block_given?)? filter.call(d_tmp) : true
    end
    ds
  end
  
  # Add relevant document set from a file
  # Format : 701 0 GX000-22-11749547 0 (TREC Qrel)
  # - filter : fetch only a subset of docs
  def add_relevant_set(file , &filter)
    #puts file
    @rl = RelevantDocumentSet.new( 'rel' )
    dsvread(file).find_all{|e| (block_given?)? filter.call(e) : true }.each do |l|
      @rl.add_doc RelevantDocument.new( l[2] , :qid => l[0].to_i , :relevance => l[3].to_i ) #if l[3].to_i > 0
      #puts @rl.docs.last.qid
    end
    @rs.each{|k,v| v.rl = @rl}
    @qs.each{|k,v| v.set_relevant_set(@rl)}
    info("relevant set added.")
  end
  
  # Add query & result set
  # - build query based on 1) given adhoc topic 2) topic_file & RegExp pattern (&filter)
  # - limit query by range as is needed
  # - run query (if needed)
  # - add result set
  # - get statistics (using trec_eval)
  def create_query_set(set_name , o = {} , &filter)
    qs = QuerySet.new( set_name , o)
    o[:offset] ||= $offset
    o[:file_topic] ||= $file_topic
    o[:topic_pattern] ||= $ptn_qry_title
    
    #Read topic file & generate query list
    topics = o[:adhoc_topic] || 
    IO.read(to_path(o[:file_topic])).scan(o[:topic_pattern]).
    map{|e| (o[:adhoc_topic])? e[0] : e[0].gsub(/[^A-Za-z0-9 ]/ , " ") }.
    find_all{|e| (block_given?)? filter.call(e) : true }
    
    if topics.size < 1 then err 'No query found!' ; return end

    offset = o[:offset] || 1 ; topics.each do |t|
      qs.add_query Query.new(offset , t)
      offset += 1
    end
    
    # Restrict query by qid (for cross-validation)
    qs.qrys = qs.qrys.each{|e| e.text = "" unless o[:range] === e.qid} if o[:range] && o[:range].class == Range
    qs.qrys = qs.qrys.each{|e| e.text = "" unless o[:range].include?(e.qid)} if o[:range] && o[:range].class == Array    
    qs.qrys = qs.qrys.each{|e| e.text = "" if  o[:ex_range] === e.qid} if o[:ex_range] && o[:ex_range].class == Range
    qs.qrys = qs.qrys.each{|e| e.text = "" if  o[:ex_range].find_all{|r|r === e.qid}.size > 0} if o[:ex_range] && o[:ex_range].class == Array    
    
    qs.build(o) if !fcheck(set_name+'.qry') || $o[:redo] || o[:redo]
    qs.run(o) if !fcheck(set_name+'.res') || $o[:redo] || o[:redo]
    
    if !o[:skip_eval]
      o[:file_qrel] ||= $file_qrel
      qs.calc_stat(o[:file_qrel] , o)
    end
    
    if !o[:skip_result_set]
      #Add result set
      qs.set_result_set create_result_set(set_name+'.res' , set_name , o.
      merge(:engine=>qs.engine))#{|d| (o[:working_set])? o[:working_set].include?(d.did) : true }
    end
    qs
  end
  
  def add_query_set( query_set )
    return false if !query_set
    @qsa << @qs[query_set.name] = query_set 
    @rsa << @rs[query_set.name] = query_set.rs if query_set.rs    
  end
  
  def crt_add_query_set(set_name , o = {} , &filter)
    @qsa << @qs[set_name] = create_query_set(set_name , o.dup , &filter)
    @rsa << @rs[set_name] = @qs[set_name].rs if @qs[set_name].rs
    @qs[set_name]
    info("[crt_add_query_set] query set '#{set_name}' added.")
  end
  
  #Fetch relevance from relevant set
  def fetch_data
    # Relevance
    #@rl.calc_count_rel
    h_rl = @rl.docs.map_hash{|d| [[d.did,d.qid].join , d.relevance]}
    @rs.each{|k,v| v.docs.each{ |d| d.fetch_relevance(h_rl) }}
    info "relevance fetched..."
  end
  
  #Calc basic statistics
  def calc_stat
    @rs.each {|k,v| v.avg_prec ; v.avg_recall }
    info "map calculated..."
  end

  def calc_length_stat
    length_stat_collection()
    @rs.each{|k,v| length_stat_docset v }
    length_stat_docset @rl if @rl
    info "length stat calculated..."
  end
  
private
end
