load 'app/ilab.rb'

$path = 'irta'

col = ['enron']


class String
  def find_tag_enron(tag_name)
    r = self.scan(/^#{tag_name}\: (.*)/)
    r[0]
  end
end

$fields = {"enron"=>['Date','Subject','From','X-To','X-cc','X-FileName']}
$i = 1
col.each do |c|
  traverse_path("#{$path}/raw/#{c}", :filter=>/\.$/, :recursion=>true) do |fp , fn|
    fc = IO.read(fp)
    #debugger
    new_path = "#{$path}/doc/#{c}/#{fp.gsub(/\//,'_')}xml"
    fields = $fields[c].map_hash{|e|[e, fc.find_tag_enron(e)]}
    text = 
    result = "<DOC>
<DOCNO>#{fc.find_tag_enron('Message-ID')}</DOCNO>
<DOCHDR>
blah
</DOCHDR>
#{fields.map{|k,v|"<#{k}>#{v}</#{k}>"}.join("\n")}
#{fc}
</DOC>
"
    File.open(new_path, 'w'){|f|f.puts result}
  end
end
