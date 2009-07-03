#Document Model
class ILabDocument
  attr_accessor :dno , :text , :group , :size , :m , :qid ,  :selected , :relevance , :remark
  attr_reader :did , :type , :title
  
  def initialize( id , o = {})
    @text = "" ; @selected = false
    @did = id
    @dno = o[:dno] #Internal Number used in Index
    @qid = o[:qid]
    @relevance = o[:relevance]
    @remark = o[:remark]
    @o = o
    @m = {}     # Metadata Hash
    @size = 0
  end
  
  def fetch_info(str, title_field, o = {})
    @m = str.split(/^--- \w+ ---$/)[1].scan(/^([a-z_]+):(.*)$/).map_hash{|e|[e[0].to_sym , e[1]]}
    @text = str.split(/^--- \w+ ---$/)[4].gsub(/\s*\<DOC\>.*\<\/DOCHDR\>\s/m,"").gsub(/\s*\<\/DOC\>\s/m,"")
    @url = @m[:url]
    @title = @text.scan(/#{title_field}\>(.*?)\<\/#{title_field}/i).flatten.first || @text.scan(/.*/).first || @m[:title]
    @title = "NONAME" if @title.size < 2
    @type = (@url)? @url.scan(/\w+$/).first : 'html'
    true
  end

  def satisfy?( o )
    size_range = o[:size] || (0..MAX_NUM)
    did_range = o[:did] || (0..MAX_NUM)
    title_pattern = o[:title] || PTN_WORD
    (size_range === @size && did_range === @did && title =~ title_pattern)
  end
end


class RelevantDocument < ILabDocument
  def initialize( id , o = {} )
    super id , o
  end
end

class ResultDocument < ILabDocument
  attr_accessor :rank,:score
  include Math
  def initialize( id , o = {} )
    super id , o
    @rank = o[:rank]
    @score = o[:score]
  end
  
  #Normalized Exponential Score (Rank#1 : 1.0)
  def score_r(max_score)
    raise DataError , "[score_r] #@score > #{max_score}" unless @score <= max_score
    @score_r ||= @score - max_score
  end

  #Normalized Exponential Score (Rank#1 : 1.0 ~ Rank #1000 : 0)
  def score_rn(max_score , min_score)
    raise DataError , "[score_nr] #@score > #{max_score} || #@score < #{min_score}" unless max_score >= min_score and max_score >= @score and @score >= min_score
    score_rn = (Math.exp(@score) - Math.exp(min_score)) / (Math.exp(max_score) - Math.exp(min_score))
    (score_rn > 0)? log(score_rn) : MIN_NUM
    #Math.slog(score_rn)
  end
  
  def fetch_relevance( h_rl )
    @relevance = h_rl[[@did,@qid].join] || -9
  end
end
