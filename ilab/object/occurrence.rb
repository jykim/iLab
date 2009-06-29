#
class Occurrence
  DEF_WEIGHT = 1
  attr_accessor :tf
  attr_reader :doc , :term , :title , :dtw , :p_cnt , :s_cnt , :w_cnt 
  def initialize(doc , term , cnt_a = nil)
    @doc = doc    #Document containing this occurrence
    @term = term
    @tf = 0 #Term Frequency
    @dtw = 0.0 #Document-Term Weight (td-idf weighting)
    @p_cnt = [] ; @s_cnt = [] ; @w_cnt = []
    #add_occurrence(cnt_a)
  end
  
  def add_occurrence( cnt_a )
    @p_cnt[@tf] , @s_cnt[@tf] , @w_cnt[@tf] = *cnt_a
    @tf += 1
  end
  
  def tid
    @term.tid
  end
  
  def title
    @term.title
  end
  
  def satisfy?( o )
    otf_range = o[:otf] || (0..MAX_NUM)
    dtw_range = o[:dtw] || (0..MAX_NUM)
    (otf_range === @tf && dtw_range === @dtw)
  end
  
  #Calc. Document-term Weight
  # - Run this only after all documents are added to the document_set
  def calc_dtw( no_docs )
    @dtw = @tf * Math.log( no_docs / @term.df )
  end
  
  #Okapi-BM25 Measure
  def calc_okapi( no_docs , avdl )
    k1 = 1.2
    b = 0.75
    #Inverse df
    idf = Math.log( (no_docs - @term.df + 0.5) / (@term.df + 0.5) )
    #Relative doc len
    rdlen = k1 * ( (1-b) + + b * dl)
    @okapi = 1
  end
  
  def to_s
    s = sprintf("D[%4d|%15s] O[%4d|%15s] tf: %4d  df:%4d  dtw: %4.1f ", @doc.did , @doc.title.scan(PTN_WORD)[0] , tid , title , @tf , @term.df , @dtw)
    s += locations
  end
  
  def locations
    sprintf("[%s],[%s],[%s]" , @p_cnt.join(',') , @s_cnt.join(',') , @w_cnt.join(',') )
  end
  
  def location(i)
    sprintf("%d,%d,%d" , @p_cnt[i], @s_cnt[i] , @w_cnt[i] )
  end

end
