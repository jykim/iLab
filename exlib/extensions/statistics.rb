
# Statistical Functions
# Included to Array
module Statistics
  include Math
  #Determine the type of elements TODO
  def element_type
    type = []
    each{|e| e.class}
  end
  
  def sum_values
    if !length
      return nil
    else
      inject(0){|sum,n|sum + n}
    end
  end
  
  # For [weight,value] array
  def wavg
    return nil if self[0].size != 2
    inject(0){|sum,e|sum + (e[0]*e[1])} / inject(0){|sum,e|sum + e[0]}.to_f
  end

  # Difference for the pair of [x-value , y-value]
  def diff( other )
    result = 0 ; self.each do |e|
      if oe = other.find{|oe|oe[0] == e[0]}
        result += (oe[1] - e[1]).abs
      else # when other element not found
        result += e[1]
      end
    end
    result
  end
  
  def mean(o = {})
    #ratio of items to be excluded 
    #TODO : graceful degradation when no. of elements is high
    if( o[:exclude] ) 
      exc_count = (o[:exclude] * 0.5 * size).to_i
      target = sort[exc_count..(size-1-exc_count)]
      (target.size > 0)? target.mean : mean
    else
      sum_values / length.to_f
    end
  end
  
  alias avg mean

  def median
    sort[size/2]
  end

  def var
    collect{|e| e**2}.mean - mean**2
    #m = mean
    #inject(0){|sum,n|sum + (n-m)**2 } / length
  end
  
  def stdev
     Math.sqrt(var)
  end
  
  def covar( other )
    return nil if length != other.length
    tmp = [] ; 0.upto(length - 1) do |i|
      tmp << self[i] * other[i]
    end
    tmp.mean - mean * other.mean
  end
  
  def pcc( other )
    return nil if length != other.length# || (stdev == 0 || other.stdev == 0)
    covar( other ) / (stdev * other.stdev)
  end
  
  def r
    Math.sqrt(inject(0){|sum,e| sum + e * e})
  end
  
  def to_norm()
    collect{|e| e.to_f / r}
  end
  
  def to_p()
    if self[0].class == Array
      v_sum = map{|e|e[1]}.sum
      map{|e|[e[0] , e[1]/v_sum.to_f]}
    else
      collect{|e| e.to_f / sum}
    end
  end
end
