load 'app/ilab.rb'

$path = './'

col = ['enron']


class String
  def find_tag_enron(tag_name)
    r = self.scan(/^#{tag_name}\: (.*)/)
    r[0]
  end
end

$fields = {"enron"=>['Date','Subject','From','To']}
$i = 1
col.each do |c|
  traverse_path("#{$path}/raw/#{c}", :filter=>/\.$/, :recursion=>true) do |fp , fn|
    fc = IO.read(fp)
    #debugger
    new_path = "#{$path}/doc/#{c}/#{fp.gsub(/\//,'_')}xml"
    fields = $fields[c].map_hash{|e|[e, fc.find_tag_enron(e)]}
    fields['Body'] = fc.split("\r\n\r\n")[1..-1]
    #puts fields['Body']
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
    fields.each{|k,v| File.open("#{$path}/doc/#{c}_#{k}.txt", 'a'){|f|f.puts v}}
    File.open("#{$path}/doc/#{c}_All.txt", 'a'){|f|f.puts fc}
  end
end
