module IR
  # Collection is like a index
  # - used by Searcher, Indexer and InferenceNetwork
  # - contains document list and term statistics
  # - can be initialized from file or 
  class Collection
    attr_accessor :docs, :lm
    def initialize(docs = nil, o={})
      @docs = docs || []
      @lm = LanguageModel.create_by_merge(docs.map{|d|d.lm.f})
    end
    
    # Used by Indexer
    def serialize_to_file()
      
    end
    
    def add_document(doc)
      @docs << doc
      @lm.update(doc.lm.f)
    end
  end
end