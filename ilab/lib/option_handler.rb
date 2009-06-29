#
# - Requirement : Hash of option, '@o'
module OptionHandler
  def [](param_name)
    @o[param_name]
  end
  
  def []=(param_name , param_value)
    @o[param_name] = param_value
  end
  
  def o
    @o.inspect
  end
end