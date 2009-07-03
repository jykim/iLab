
#Term Model
class Term
  attr_accessor :df , :tf , :group , :adtw
  attr_reader :tid , :title , :remark , :d_cnt , :p_cnt , :s_cnt , :w_cnt
  
  def initialize( tid , title , remark = nil)
    @tid = tid
    @title = title
    @remark = remark
    @df = 0      #Document Frequency - In how many documents is this term found?
    @tf = 1      #Term Frequency (global)
    @adtw = 0
    @group = []
    @d_cnt = [] ; @p_cnt = [] ; @s_cnt = [] ; @w_cnt = []
    @nows = title.scan( PTN_WORD ).length #No. of words
  end
  
  #Given hash of conditions, return if current instance satify the condition
  def satisfy?( o )
    tid_range = o[:tid] || (0..MAX_NUM)
    tf_range = o[:tf] || (0..MAX_NUM)
    df_range = o[:df] || (0..MAX_NUM)
    adtw_range = o[:adtw] || (0..MAX_NUM)
    title_pattern = o[:title] || PTN_WORD
    (adtw_range === @adtw && tid_range === @tid && tf_range === @tf && df_range === @df && @title =~ title_pattern)
  end
  
  def to_s
    s = sprintf("T[%4d|%15s] df: %4d tf: %4d", tid , title , @df , @tf)
    s += sprintf(" adtw: %5.1f" , @adtw) if @adtw > 0
    s += sprintf(" %s" , remark) if remark
  end
  
#  def inspect
#    sprintf("Term [%4d|%15s]", tid , title)    
#  end
end

