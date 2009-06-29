# Query Model
# == Requirement
# * Queries can run individually or as a set
class Query
  include QueryHelper , ILabHelper
  attr_accessor :text, :size, :rel_doc_no, :rs, :rl
  attr_reader :qid
  
  def initialize( id , text , o = {})
    @text = text
    @qid = id
    @o = o
    @size = 0
    @rel_doc_no = 0
  end
  
  def satisfy?( o )
    size_range = o[:size] || (0..MAX_NUM)
    qid_range = o[:qid] || (0..MAX_NUM)
    text_pattern = o[:text] || PTN_WORD
    (size_range === @size && qid_range === @qid && text =~ text_pattern)
  end
  
  #deprecated
  def run(o = {})
    o.merge!({:offset => @qid})
    build_n_run( @qid.to_s , [@text] , o )
  end

  def to_s
    sprintf("Q[%4d|] %40s (size: %d)" , @qid , text , @size )
  end
end
