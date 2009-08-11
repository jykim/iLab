def get_code(group)
  begin
    SysCode.find_all_by_group(group).map{|e|[e.title,e.content]}
  rescue Exception => e
    error("[get_code] Error #{e}")
  end  
end

def get_config(title)
  begin
    SysConfig.find_by_title(title).content    
  rescue Exception => e
    error("[get_config] Error #{e}")
  end
end

def parse_value(value)
  return value if value.class != String
  begin
    eval(value)
  rescue Exception => e
    value
  end
end

# - assume more than two lines of file, with the header in the first line
def read_csv(filename, o = {})
  #header = o[:header] || true
  content = FasterCSV.parse(IO.read(filename).to_lf, :row_sep => "\n")
  content[1..-1].map{|c|content[0].map_hash_with_index{|h,i|[h.downcase.to_sym, c[i]]}}
end

def info(str)
  puts str
  $lgr.info str if $lgr
end

def error(str)
  puts str
  $lgr.error str if $lgr
end

def debug(str)
  puts str
  $lgr.debug str if $lgr
end