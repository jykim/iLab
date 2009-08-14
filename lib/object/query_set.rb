# Set of Queries
# - Delegate engine-specific operation to some SearchEngineInterface class
class QuerySet
  attr_accessor :short_name, :name , :qrys , :qh , :rs , :o , :stat , :engine
  include ILabHelper , QueryHelper , OptionHandler, Math
  PROB_UNFOUND = 0.0000001 #Float::EPSILON
  
  # - hash(@qh) & array(@qrys) data structure for storing queries
  def initialize( name , o = {})
    @name = name
    @qrys = []
    @qh = {}
    o[:engine] ||= DEFAULT_ENGINE_TYPE
    @engine = case o[:engine]
      when :indri : IndriInterface.new(@name , o)
      end
    @o = o
  end
  
  def add_query( query )
    @qrys << query
    @qh[query.qid] = query
  end
  
  def build(o = {})
    @engine.build_query( @qrys.map{|q|q.text} , @name , o.merge(:offset => @qrys[0].qid))
  end
  
  def run( o = {})
    @engine.run_query(@name+'.qry' , @name , o)
    unless fcheck(@name+'.res')
      info "[QuerySet:run] Running again #{@name}"
      @engine.run_query(@name+'.qry' , @name , o)
    end
  end
  
  #Get collection score using collection statistics based on given query
  def get_col_score(query, o = {})
    words = query.split(/\s+/).map{|w|@engine.kstem(w)}
    score = 1
    bglm = $engine.get_col_freq(:whole_doc=>true)['DOC']
    case (o[:col_score] || "cql")
    when "cql"
      clm = @engine.get_col_freq(:whole_doc=>true)['DOC']
      #clm_s = clm.smooth(0.1,bglm)
      words.each do |w|
        #info("[get_col_score] zero prob for #{@name}/#{w}") if !clm[w]
        #err("[get_col_score::clm_s] zero prob for #{@name}/#{w}") if !clm_s[w]
        score += slog((clm[w])? clm[w] : PROB_UNFOUND)
        #score *= clm_s[w]
      end
    when "nmp"
      cflm = @engine.get_col_freq()
      words.each do |w|
        score += slog(cflm.map{|k,v|(v[w])? v[w] : PROB_UNFOUND}.avg)
      end
    end
    score
  end
  
  # Get statistics using trec_eval
  # - @stat = {"qid1"=>{"measure1"=>0.01, ...}}
  def calc_stat(file_qrel, o={})
    run_trec_eval(file_qrel , @name+'.res') if !fcheck(@name+'.eval') || $o[:redo] || o[:redo]
    a = dsvread(@name+'.eval')
    @stat = @qh.map_hash{|k,v|[k.to_s,nil]}
    a.each{|l| @stat[l[1]] = {} if !@stat[l[1]] ; @stat[l[1]][l[0]] = l[2].to_f.r3}
    # @stat2 = {} ; a.each{|l| @stat2[l[0]] = {} if !@stat2[l[0]] ; @stat2[l[0]][l[1]] = l[2].to_f}
    @stat
  end
  
  def get_qrys( o = {} )
    order_by = o[:order_by] || "qid"
    a = @qrys.find_all{|q| q.satisfy?(o) }.sort_by{|q| q.send(order_by) }
    apply_ordering(a , o)
  end
  
  def set_result_set( docset )
    @rs = docset
    @qh.each do |k,v| 
      v.rs = ResultDocumentSet.new(docset.name+'_q'+k.to_s)
      v.rs.import_docs( docset.dhq[k] )
    end
  end

  def set_relevant_set( docset )
    @qh.each do |k,v|
      v.rl = RelevantDocumentSet.new(docset.name+'_q'+k.to_s)
      v.rl.import_docs( docset.dhq[k] ) if docset.dhq[k]
    end
  end
private
end
