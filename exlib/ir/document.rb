module IR
  class Document
    attr_accessor :did, :text, :lm, :flm
    def initialize(did, input, o = {})
      @did = did
      case input.class.to_s
      when 'String'
        @lm = LanguageModel.new(input)
        if o[:fields]
          @flm = {} ; @fields = o[:fields]
          o[:fields].each{|f|
            @flm[f] = LanguageModel.new(input.find_tag(f))}
        end
      when 'Hash' #{field1=>flm1,field2=>flm2,...}
        @flm = input
        #debugger
        @lm = LanguageModel.create_by_merge(input.map{|k,v|v.f})
        assert_equal(@flm.map{|k,v|v.size}.sum, @lm.size)
      end
    end
    
    def serialize()
      template = ERB.new(IO.read("lib/ir/template/doc_trectext.xml.erb"))
      template.result(binding)
    end
  end
end