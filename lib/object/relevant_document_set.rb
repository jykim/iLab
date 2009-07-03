class RelevantDocumentSet < DocumentSet
  attr_reader :count_rel
  def initialize( name , o = {})
    super(name , o)
    @count_rel = {}
  end
  
  def calc_count_rel
    @docs.find_all{|d|d.relevance > 0}.group_by{|d|d.qid}.each{|qid,docs| @count_rel[qid] = docs.size}
  end
end
