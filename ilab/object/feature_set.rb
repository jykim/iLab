class Feature
  attr_accessor :type, :name
  def initialize(name, type, o)
    
  end
end

class FeatureSet
  def initialize(args)
    @cols = []
    @rows = []
  end
  
  def add_col(name, type, o = {})
    @cols << Feature.new(name, type, o)
  end
  
  #data = [feature1, ..., label]
  def add_row(id, data, o = {})
    return "[FeatureSet::add_row] Invalid no. of elements" if row.size != 0 && row.size != @cols.size
    @rows << {:id=>id, :data=>data}
  end
  
  #
  def export_rows(o = {})
    result = []
    result << @cols.map{|c| c.name} if o[:header_row]
    @rows.each_with_index do |r,i|
      if o[:row_range] && !(o[:row_range] === r[:id])
      row = @cols.map_with_index do |c,j|
        case c.type
        when :log10
          Math.log10(r[:data][j])
        when :round
          r[:data][j].round
        else
          r[:data][j]
        end
      end#col
      result << row
    end#row
    result
  end
  
  def get_cols()
    
  end
end
