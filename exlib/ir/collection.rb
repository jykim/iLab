# Collection is like a index
# - used by Searcher, Indexer and InferenceNetwork
# - contains document list and term statistics
# - can be initialized from file or 
class Collection
  attr_accessor :cid, :docs, :lm
  def initialize(cid, docs = nil, o={})
    @cid = cid
    @docs = docs || []
    @lm = o[:lm] || LanguageModel.create_by_merge(docs.map{|d|d.lm.f})
  end
  
  # Used by Indexer
  def to_yaml()
    result = [@cid,@lm.f]
    result << @docs.map{|d|d.to_yaml}
    result.to_yaml
  end
  
  def self.create_from_yaml(yaml_str)
    yaml_obj = YAML.load(yaml_str)
    docs = yaml_obj[2].map{|e|Document.create_from_yaml(e)}
    lm = LanguageModel.new(yaml_obj[1])
    result = Collection.new(yaml_obj[0], docs, :lm=>lm)
    puts "[create_from_yaml] Collection initialized (#{result.lm.size} / #{result.docs.map{|d|d.lm.size}.sum})"
    #debugger
  end
  
  def add_document(doc)
    @docs << doc
    @lm.update(doc.lm.f)
  end
end