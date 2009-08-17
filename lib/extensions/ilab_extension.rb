
class File
  def name(ext = "")
    File.basename(path, ext)
  end
end

class Fixnum
  def to_log( deno = 10)
    (self>0)? Math.log(self) / Math.log(deno) : 0
  end
end

def sample_ints(range, no)
  result = {} ; iter, max_iter = 0, 1000000
  while true do
    break if result.size == no
    result[rand(range)] = true
    puts "[sample_ints] max_iter exceeded #{range} / #{no}!" if iter >= max_iter
    iter += 1
  end
  result
end

class NilClass
  def to_hash
    {}
  end
  
  #def [](data)
  #  error "[nil] [] was called for nil" # in #{__FILE__}:#{__LINE__}"
    #raise ArgumentException
  #  nil
  #end
end

class String
  def capital?
    !(self == downcase)
  end
  
  def to_num
    case self
    when /^:/: to_sym
    when /^[0-9]+\.[0-9]$/: to_f
    when /^[0-9]+$/: to_i
    when 'true' : true
    when 'false' : false
    else
      self
    end
  end
  
  # Format to string suitable for filename
  def to_fname
    gsub(/\s|\//,"_").gsub(/\(/,"[").gsub(/\)/,"]")
  end
  
  WORD_PTN = /[0-9a-zA-Z]+/
  def cut(ratio, o = {})
    o[:ptn] ||= WORD_PTN
    o[:method] ||= :order
    words = self.scan(WORD_PTN)
    return words if words.size < 2
    num_cut = (words.size*ratio).to_i
    case o[:method]
    when :order
      words[0..(words.size - num_cut)]
    when :random
      ints = sample_ints(words.size, num_cut)
      i = -1 ; words.delete_if{|e|i += 1 ; ints[i]}
    end
  end

  def to_a
    if self =~ /^\|.*\|$/
      split("|")[1..-1]
    else
      [self]
    end
  end
  
  #Leave only ascii chars
  def remove_nonascii(replacement = " ")
    n=split("")
    slice!(0..size)
    n.each{|b|
      if b[0].to_i< 33 || b[0].to_i>127 then
        concat(replacement)
      else
        concat(b)
      end
    }
    to_s
  end
end

class Range
  def -(arg)
    to_a - arg.to_a
  end
end

module IRMeasure
  # Input : ranked list of documents with judgments
  # i.e. [true,true,false...]
  def avg_prec
    precs = [] ; no_rels = 0
    each_with_index do |e , i|
      if e == true
        no_rels += 1
        precs << no_rels / (i+1).to_f
      end
    end
    (precs.size>0)? precs.mean : 0
  end
  
  # Input : array of relevance judgments
  def dcg1(rank = 5)
    if rank == 1
      first
    else
      first + self[1..rank-1].map_with_index{|e,i| self[0..i+1].sum / log2(i+2) }.sum
    end
  end
  
  def dcg2(rank = 5)
    self[0..rank-1].map_with_index{|e,i| ((2 ** self[0..i].sum) -1) / log2(i+2) }.sum
  end
end

class Matrix
  def []=(i , j , value)
    @rows[i][j] = value
  end
end

class Hash
  #include ProbabilityDistribution
  def max_pair
    max{|e1,e2|e1[1]<=>e2[1]}
  end

  def to_arr(labels)
    labels.map{|e|self[e]}
  end
  
  def normalize
    map_hash{|k,v|[k , (v.to_f - values.min)/(values.max - values.min)]}
  end
end

class Array
  include IRMeasure
  
  # Get the average of kth column of given table
  def avg_col(k)
    map{|e|e[k]}.find_all{|e|e}.avg
  end
  
  def sort_val
    sort_by{|e|e[1]}.reverse
  end
    
  #Generate Array of Cartesian Product
  def cproduct(arr)
    self << nil if size == 0
    arr  << nil if arr.size == 0
    result = []
    each{|e|result.concat arr.map{|e2|[e,e2].flatten}}
    result
  end

  # Return all the elements that given string matches
  def pfind(str)
    a = find_all{|e|str =~ ((e.class == Regexp)? e : /#{e}/)}
    (a.size == 1)? a.first : a
  end

  def to_h()
    map_hash{|e|[e[0],e[1]]}
  end
  
  #Create hash by assigning labels to each element of array
  def to_hash(labels)
    return nil if labels.size != size
    map_hash_with_index{|e,i|[labels[i], e]}
  end
  
  #self : [[k1,v1],[k2,v2],...]
  def to_p(factor = 1.0)
    sum = map{|e|e[1]}.sum.to_f
    map{|e| [e[0] , e[1] / sum * factor]}
  end
  
  # Format each row as table with min/max highlight
  # self : [e1-1, e1-2, ...]
  def to_tbl(o={})
    style = (o[:style])? "{#{o[:style]}}. " : ""
    a = case o[:mode]
        when :max
          max_e = max.to_f
          map{|e|(e==max_e)? "*#{e.to_s}*" : "#{e}(#{((e-max_e)/max_e*100).round_at(1)}%)"}
        when :min
          min_e = min.to_f
          map{|e|(e==min_e)? "#{e.to_s}" : "#{e}(#{((e-min_e)/min_e*100).round_at(1)}%)"}
        else
          self
        end
    "|"+style+a.join('|')+"|"
  end

  #  combination of members
  # [a,b,c] => [[a,b],[a,c],[b,c]]
  def to_comb
    a = []
    map_with_index{|e1,i| map_with_index{|e2,j| a << [e1,e2] if i < j}}
    a
  end

  # Return cumulative distribution
  # self : [[k1,v1],[k2,v2]]
  def to_cum
    cum_val = 0
    sort_by{|e|e[0]}.map{|e|[e[0] , cum_val+=e[1]]}
  end

  # Average given distributions(Hash)
  #def avg_dists
  #  h = Hash.new
  #  each do |d|
  #    d.each do |k,v|
  #      if !h[k] then h[k] = [] end
  #      h[k] << v
  #    end
  #  end
  #  h.map_hash{|k,v|[k , v.sum/size.to_f]}
  #end
  #
  ##
  #def concat_dists
  #  h = Hash.new
  #  each_with_index do |d,i|
  #    d.each do |k,v|
  #      if !h[k] then h[k] = Array.new(size) end
  #      h[k][i] = v
  #    end
  #  end
  #  h.to_a.map{|e|e.flatten}.sort_by{|e|e[0]}
  #end
  
  def correl_rank( other )
    return nil if size != other.size
  end

  # Degree of association btw. two arrays
  def calc_assoc(other , o = {})
    type = o[:type] || :sum
    #weight_penalty = o[:penalty] || 0
    
    a = (self & other).length
    b = length - a
    c = other.length - a
    #d = o[:total] - (a+b+c)
    
    case type
    when :sum     then a #- weight_penalty * (b + c)
    when :jaccard then a.to_f / (a + b + c)
    when :cosine  then a / (Math.sqrt(a+b) * Math.sqrt(a+c))
    #when :yules   then Math.sqrt( (a * d) / (b * c) )
    #when :minfo   then o[:total]
    end
  end
end
