class TermRelation
  DEF_WEIGHT_D = 1
  DEF_WEIGHT_P = 3
  DEF_WEIGHT_S = 5
  MAX_DISTANCE = 45
  
  attr_accessor :distance , :processed , :measures , :measure_names
  attr_reader :t1 , :t2
  def tid1
    @t1.tid
  end
  
  def tid2
    @t2.tid    
  end
  
  def initialize(term1 , term2 , distance = 0.0)
    @t1 = term1
    @t2 = term2
    @distance = distance
    @processed = false
    @measures = []
    @measure_names = []
  end
  
  #TODO Make it dynamic!
  def satisfy?( o )
    as_range = o[:as] || (0..MAX_NUM) # doc. freq. for relation
    ps_range = o[:ps] || (0..MAX_NUM)
    (as_range === @as && ps_range === @ps)
    true
  end
  
  def to_s
    s  = sprintf("R[%4d|%12s]-[%4d|%12s] tf2: %4d ", @t1.tid , @t1.title , @t2.tid , @t2.title , @t2.tf)
    s += sprintf(" dist: %4.2f" , @distance) if @distance > 0
    @measures.each_with_index{|e,i| s += sprintf("%s: %5.2f ", @measure_names[i] , e)}
    s += sprintf(" %s" , @t2.remark) if @t2.remark
    s
  end

  # Calc. Proximity Score
  def calc_ps( o = {} )
    weight_d = o[:weight_d] || DEF_WEIGHT_D
    weight_p = o[:weight_p] || DEF_WEIGHT_P
    weight_s = o[:weight_s] || DEF_WEIGHT_S
    
    ps =  weight_d * @t1.d_cnt.calc_assoc( @t2.d_cnt , o ) if weight_d > 0
    ps += weight_p * @t1.p_cnt.calc_assoc( @t2.p_cnt , o ) if weight_p > 0
    ps += weight_s * @t1.s_cnt.calc_assoc( @t2.s_cnt , o ) if weight_s > 0
    ps
  end

  # Calc. Word-level Proximity Score
  def calc_wps(o = {})
    max_distance = o[:max_distance] || MAX_DISTANCE
    w1 = @t1.w_cnt ; w2 = @t2.w_cnt 
    @i = 0 ; @j = 0 ; g_score = []; w1_iso = 0 ; w2_iso = 0
    # Until we exhause occurrence of both terms
    # Always start with a new group (b_loc/b_term)
  begin
    while true
      #At this point, which term do we have and where?
      b_term , b_loc = get_term_loc(w1[@i] , w2[@j])
      #What is current term and where?
      c_term , c_loc = get_next_term_loc(b_term , w1 , w2)

      if( c_loc - b_loc > max_distance || b_term == c_term || !in_same_doc?(b_loc , c_loc) )
        #puts "Moving on (#{b_term}::#{b_loc} -> #{c_term}::#{c_loc})"
        if b_term == 1 then w1_iso += 1 else w2_iso += 1 end
        next
      end
      
      n_term , n_loc = get_next_term_loc(c_term , w1 , w2)
      # c_term - n_term group
      if n_term != c_term && n_loc - c_loc < c_loc - b_loc
        g_score << n_loc - c_loc 
        #puts "C3-1 G#(#{c_term}::#{c_loc} ~ #{n_term}::#{n_loc}) : #{g_score.last}"
        nn_term , nn_loc = get_next_term_loc(n_term , w1 , w2)
        if c_term == 1 then w1_iso += 1 else w2_iso += 1 end
      else # b_term - c_term group
        g_score << c_loc - b_loc 
        #puts "C3-2 G#(#{b_term}::#{b_loc} ~ #{c_term}::#{c_loc}) : #{g_score.last}"
      end
    end#while
  rescue IndexError
    #puts "Process ended @ (#@i,#@j) / #{w1_iso} , #{w2_iso}"
  end#begin
    g_score.inject(0){|sum,e| sum + 1.0 / e if e > 0} #) / Math.exp(w1_iso * w2_iso) 
  end

private
  def in_same_doc?(loc1 , loc2)
    loc1 / Document::MAX_TMOCS == loc2 / Document::MAX_TMOCS
  end
  
  #Next closest location & term
  def get_next_term_loc(cur_term , w1 , w2)
    next_term , next_loc = if cur_term == 1 
      if @i + 1 == w1.length : raise IndexError end
      get_term_loc(w1[@i+=1] , w2[@j])
    else
      if @j + 1 == w2.length : raise IndexError end
      get_term_loc(w1[@i] , w2[@j+=1])
    end
    #puts "(#@i,#@j) C#{cur_term}->N#{next_term}::#{next_loc}"
    #[next_term , next_loc ]
  end

  def get_term_loc(loc1 , loc2)
    term , loc = (loc1 < loc2)? [1 , loc1] : [2 , loc2]
    #puts "#{term}::#{loc}"
    #[term , loc]
  end
end