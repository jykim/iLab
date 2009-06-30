load 'ilab.rb'
input_dir = '/work2/COLLECTIONS/monster'
batch_edit(input_dir, :new_path=>'monster/col/raw') do |e|
  e.gsub!(/\<\?.*?\?\>/, "").gsub!(/\<(\/)?resumes\>/, "").gsub!(/\r\n/,"\n") #clean-up
  #puts e[0..100]
  e.gsub!(/\<(\/?)resume\>/, "<\\1DOC>").gsub!(/\<(\/?)ResumeID\>/, "<\\1DOCNO>") #tag conv.
  e.gsub(/(\<DOC\>)(\<DOCNO\>)/, "\\1\n\\2").gsub(/(\<\/DOCNO\>)/, "\\1\n<DOCHDR>\ndamn\n</DOCHDR>") #tag adding & ordering
end
