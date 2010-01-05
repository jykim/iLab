# LanguageModel Library
# - Initialize from Frequency Distribution
class LanguageModel
  attr_accessor :f, :p, :size#, :text
  PTN_TERM = /[\w]+/
  def initialize(input, o = {})
    #return if !text
    @f = case input.class.to_s
    when "Hash" # fdist
      input
    when "String"
      #@text = input
      input.clear_tags.scan(PTN_TERM).map{|e|e.downcase.stem}.to_dist
    else
      {}#raise ArgumentError
    end
    #debugger
    @size = @f.values.sum
  end
  
  def size()
    #puts "size called!" if print
    @size
  end
  
  def to_yaml
    @f.to_yaml
  end
  
  def update(fdist)
    @f = @f.sum(fdist)
  end
  
  def self.create_by_merge(fdists)
    LanguageModel.new(fdists.merge_by_sum())
  end
end