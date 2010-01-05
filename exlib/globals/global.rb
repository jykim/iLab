
def file_write(file_name , var , o = {})
  path = o[:path] || PATH_DATA
  fullpath = File.join(path,file_name)
  mode = o[:mode] || 'w'
  if o[:protect] && File.exist?(fullpath)
    return nil
  end
  File.open( fullpath  , mode){|file| file.puts var}    
end

def file_read(file , o = {})
  path = o[:path] || PATH_DATA
  IO.read(File.join(path,file))
end

def file_backup(file)
  ret = `cp #{file} #{file}.bak`
  puts "[file_backup] return = #{ret}"
  ret
end

def file_dump( dump_name , var )
  File.open( dump_name , 'w') {|f| Marshal.dump(var , f) }
end

def file_load( dump_name )
  File.open( dump_name , 'r') {|f| return Marshal.load(f) }
end

def gen_latex(filename)
  include MarkupHandler
  str = IO.read(filename).split("\n")
  @page = Page.new({:title=>str[0] , :content=>str[1..-1].join("\n")})
  template = ERB.new IO.read(RAILS_ROOT+'/app/views/main/latex.rhtml')
  str_r = template.result(binding)#.gsub(/\n/,"\r\n")
  file_write(filename+'.tex' , prepare_latex(str_r) , :path=>'.')
end

def str2time(str)
  if str.class == Time then return str end
  Time.mktime(*ParseDate::parsedate(str,true))
end
