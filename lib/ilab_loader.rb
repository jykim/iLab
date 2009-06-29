class ILabLoader  
  def self.load(i , o = {})
    if i.fcheck(i.name+'.dmp') && $dump
      puts 'Loading..'
      i.fload i.name+'.dmp'
    else
      puts 'Building..'
      build(i)
      if $dump
        i.fdump i.name+'.dmp' , i 
      else
        i
      end
    end
  end

  def self.build(i)
    # Redefine This
  end
end
