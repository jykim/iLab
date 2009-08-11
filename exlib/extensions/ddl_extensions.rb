class String
  def to_id
    gsub(/\s|\//,"_")
  end
  
  # Convert
  def to_utc()
    Time.parse(self).utc
  end
  
  def to_localtime
    begin
      to_time(:local)
    rescue Exception => e
      self
    end
  end
  
  # "k1=v1|k2=v2"
  def to_hash
    split("|").map_hash{|e|e2 = e.split("=") ; [e2[0].to_sym, e2[1]]}
  end
  
  def to_cr
    self.gsub("\n\r","\r").gsub("\n","\r")
  end
  
  def to_lf
    self.gsub("\n\r","\n").gsub("\r","\n")
  end
end

class Date
  def to_utc()
    self.to_time.utc
  end
end

class Time
  def to_ymdhms
    strftime('%Y%m%d%H%M%S')
  end
  
  #def to_s
  #  strftime('%Y-%m-%d %H:%M:%S')
  #end
  
  def to_ymd
    strftime('%Y%m%d')
  end
  
  def next_day
    tomorrow
  end
end

class Array
  def to_id
    join("#").to_id
  end
  
  # self : [[k1,v1],[k2,v2]]
  def to_hash
    map_hash{|e|e}
  end
  
  # Turn the array of feature names into values using Hash of param
  def to_val(param, o = {})
    map{|e|param[e]||o[:def_val]}
  end
end

