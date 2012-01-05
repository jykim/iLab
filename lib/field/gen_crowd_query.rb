#require 'CSV'

def gen_crowd_query(topic_id, filename ,given_queries, o = {})
  dt = CSV.parse(IO.read(filename))
  #p dt[1]
  valid_queries = dt.find_all{|e|e[1] == 'false' && e[6].to_f >= 0 && !given_queries.include?(e[5])}.
    map{|e|{:title=>e[5], :did=>e[11]}}
  invalid_queries = dt.find_all{|e|e[1] == 'true' || given_queries.include?(e[5])}.
    map{|e|[((e[16]==e[5])? e[17] : e[16]) ,e[11]]}
  
  File.open(to_path("#{topic_id}_topic_invalid"),'w'){|f|invalid_queries.each{|e|f.puts e.join("\t")}}
  write_topic(to_path("topic/#{topic_id}_topic"), valid_queries)
  write_qrel(to_path("qrel/#{topic_id}_qrel"), valid_queries.map_hash_with_index{|e,i|[i+1,{e[:did]=>1}]})
end
