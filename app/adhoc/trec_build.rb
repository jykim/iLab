load 'ilab.rb'
load 'adhoc/pd_lib.rb'
$fields =  ['SUBJECT','TEXT','TO','SENT','NAME','EMAIL']
first_doc = true
$file_hash = {}
Find.find(TREC_LIST_COL_PATH) do |fp|
  next if FileTest.directory?(fp)
  puts "#{fp} started..."
  $file_hash[fp] = IO.read(fp) if !$file_hash[fp]
  $file_hash[fp].scan(/\<DOC\>.*?\<\/DOC\>/m).each do |doc|
    did = doc.scan(/\<DOCNO\> (.*?) \<\/DOCNO\>/)[0][0]
    puts "(ORIGINAL)\n#{doc}" if first_doc
    [0.75,0.5,0.25].each do |cut_ratio|
      fnew = $fields.map_hash{|field|str = doc.find_tag(field)[0] ; [field, str]}
      #$fields.map_hash{|field|str = doc.find_tag(field)[0] ; [field, ((str) ? str.cut(cut_ratio,:method=>:random).join(" ") : "")]}
      path = TREC_PATH + "lists_new"
      #path = TREC_PATH + "lists_#{cut_ratio}_r"
      doc_new = <<END
<DOC>
<DOCNO> #{did} </DOCNO>
<DOCHDR>
damn
</DOCHDR>
<SENT> #{fnew['SENT']} </SENT>
<NAME> #{fnew['NAME']} </NAME>
<EMAIL> #{fnew['EMAIL']} </EMAIL>
<SUBJECT> #{fnew['SUBJECT']} </SUBJECT>
<TO> #{fnew['TO']} </TO>
<TEXT>
#{fnew['TEXT']}
</TEXT>
</DOC>
END
      Dir.mkdir(path) if !File.exist?(path)
      puts "(#{cut_ratio})\n#{doc_new}" if first_doc
      File.open(File.join(path, "#{did}.html"), "w"){|f|f.puts doc_new }      
    end
    first_doc = false
  end
end