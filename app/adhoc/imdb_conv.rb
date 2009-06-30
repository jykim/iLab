load 'ilab.rb'
input_dir = '/work1/jykim/prj/dbir/imdb/col/docs_plot_nd/'
batch_edit(input_dir, :new_path=>'/work1/jykim/prj/dbir/imdb/raw') do |fn , e|
  e.gsub!(/\<\?.*?\?\>\n/, "")
  e.gsub!(/\<movie\>/, "<DOC>\n<DOCNO>#{File.basename(fn)}</DOCNO>")
  e.gsub!(/\<\/movie\>/, "</DOC>")
end
