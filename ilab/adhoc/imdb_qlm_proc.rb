load 'ilab.rb'
#Extract title/year from Collection XML files
if !File.exist?("imdb_fn_title.out")
  result = []
  traverse_path("/work1/jykim/prj/dih/imdb/raw/") do |fp,fn|
    content = IO.read(fp)
    title = content.find_tag("title").first.downcase
    year = content.find_tag("year").first
    result << "#{title} (#{year})\t#{fn}"
  end
  File.open( "imdb_fn_title.out"  , "w"){|f| f.puts  result.join("\n")}
end
h = IO.read("imdb_fn_title.out").split("\n").map_hash{|e|e.split("\t")}

#Fetch title/year from Website
LABEL_CLICKS = [:qid,:query,:time,:url,:pos]
result = []
qt = []
$data = IO.read("clicks.txt.imdb").split("\n").map{|e|e.split("\t").to_hash(LABEL_CLICKS)}
if !File.exist?("imdb_query_title.out")
  $data.each do |e|
    next if !e
    webpage = run_wget("wget", e[:url].scan(/tt[0-9]+/).first+".html", e[:url], :read=>true)
    if (title = webpage.find_tag("title").first)
      title = title.downcase
      result << [e[:query].downcase, h[title]] if h[title]
      qt << [e[:query].downcase.split(" "), title.downcase.split(" ")]
    end
  end
  File.open( "imdb_query_title.out"  , "w"){|f| f.puts  result.map{|e|e.join("\t")}.join("\n")}
end
result = IO.read("imdb_query_title.out").split("\n").map{|e|e.split("\t")}#.map_hash{|e|e.split("\t")}

puts 'Finished download'
q_range=1000..1199
write_topic("topic_imdb_qlm_train", result.uniq.map{|e|e[0]}.uniq.sort[q_range].map{|e|{:title=>e}})
write_qrel("qrel_imdb_qlm_train", result.uniq.group_by{|e|e[0]}.sort_by{|k,v|k}[q_range].
           map_hash_with_index{|e,i|[i+1,e[1].map_hash{|e2|[e2[1],1]}]})

#Find out where in documents they're from
