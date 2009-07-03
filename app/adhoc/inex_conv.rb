load 'ilab.rb'

$path = 'inex'
col = ['zdnet','qmul','IDEA','HCI','dblp','cs','duis']

def sub_tag(str, tag, prefix = "")
  str.gsub!(/\<(\/?)#{tag}\>/, "<\\1#{prefix+tag.downcase}>")
end

col.each do |c|
  if File.exists?("#{$path}/doc/"+c)
    puts "Skipping #{c}..." ; next 
  end
  batch_edit("#{$path}/col/"+c , :new_path=>"#{$path}/doc/#{c}" , :filter=>/\.xml$/) do |fp , fc|
    case c
      when 'zdnet'
      fc.gsub!(/\<(\/?)doctitle\>/, "<\\1ztitle>")
      fc.gsub!(/\<(\/?)content\>/, "<\\1zcontent>")
      fc.gsub!(/\<(\/?)author\>/, "<\\1zauthor>")
      when 'qmul'
      fc.gsub!(/\<(\/?)TYPE\>/, "<\\1qtype>")
      fc.gsub!(/\<(\/?)TITLE\>/, "<\\1qtitle>")
      fc.gsub!(/\<(\/?)AUTHOR\>/, "<\\1qauthor>")
      fc.gsub!(/\<(\/?)BOOKTITLE\>/, "<\\1qbooktitle>")
      when 'IDEA'
      ['title','subt','conference','author','keywords','abstract','body','rear'].each{|e| sub_tag(fc, e, 'i')}
    when 'HCI'
      ['title','journal','author','abstract'].each{|e| sub_tag(fc, e, 'h')}
    when 'dblp'
      ['title','booktitle','author'].each{|e| sub_tag(fc, e, 'd')}
    when 'cs'
      ['title','keywords','author','journal','abstract'].each{|e| sub_tag(fc, e, 'c')}
    when 'duis'
      ['title','journal','author','abstract','subject-descriptors'].each{|e| sub_tag(fc, e, 'u')}
    end
    "<DOC>
<DOCNO>#{c+File.basename(fp,'.xml')}</DOCNO>
<DOCHDR>
blah
</DOCHDR>
#{fc}
</DOC>
"
  end
end
