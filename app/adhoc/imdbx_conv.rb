load 'app/ilab.rb'
batch_edit(ARGV[0], :new_path=>"col_new", :recursion=>true) do |fn , e|
  #puts "#{fn}"
  e.gsub!(/\<\?.*?\?\>/, "")
  e.gsub!(/^\<(movie|person)(| .*?)\>/, "<DOC>\n<DOCNO>#{File.basename(fn, ".xml")}</DOCNO>")
  e.gsub!(/^\<\/(movie|person)\>/, "</DOC>")
end

# Command
# ruby -I /prj/dih/iLab/ -I /prj/dih/iLab/rubylib /prj/dih/iLab/app/adhoc/imdbx_conv.rb col
