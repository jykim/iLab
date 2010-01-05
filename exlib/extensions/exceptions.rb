class DataError < Exception
  def initialize(msg)
    err "[DataError] #{msg}"
  end
end

class ExternalError < Exception
  def initialize(msg)
    err "[ExternalError] #{msg}"
  end
end

#class ArgumentError < Exception
#  def initialize(msg)
#    err "[ArgumentError] #{msg}"
#  end
#end