# LanguageModel Library
# - Initialize from Frequency Distribution
class LanguageModel
  attr_accessor :f, :p, :size, :text
  PTN_TERM = /[\w]+/
  def initialize(input, o = {})
    #return if !text
    @f = case input.class.to_s
    when "Hash" # fdist
      input
    when "String"
      @text = input
      input.clear_tags.scan(PTN_TERM).map{|e|e.stem}.to_dist
    end
    @p = @f.to_p # FIXME storage <-> speed tradeoff?
    @size = @f.values.sum
  end
  
  def update(fdist)
    @f = @f.sum(fdist)
  end
  
  def self.create_by_merge(fdists)
    LanguageModel.new(fdists.merge_by_sum())
  end
end