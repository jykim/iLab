load 'ilab.rb'

# Convert each field so that collection type can be prefixd 
PD_PIDS.each do |pid|
  $col_types.each do |col_type|
    fields = if col_type != 'lists'
      ['title','url','abstract','date','text']
    else
      ['subject','content','to','sent','name','email']
    end
    batch_edit("pd/raw/#{pid}/#{col_type}_doc", :new_path=>"pd/raw/#{pid}/all_doc/#{col_type}_doc") do |fname, fcontent|
      fields.each do |field|
        fcontent = fcontent.replace_tag(field, "#{col_type}_#{field}")
      end
      fcontent
    end
  end#col_type
end

#result = []
#traverse_path($in, :filter=>/^text/) do |fp,fn|
#  content  = IO.read(fp)
#  next if content.size < 10
#  filename = IO.read(fp.sub(/text/,"name")).strip.scan(/\w+\.\w+/).first
#  File.open( File.join($out, filename+".out")  , "w"){|f| f.puts content.gsub(/\r\n/,"\n")}
#end
#