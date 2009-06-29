# < Distributed Processing >
# ex) $o={:k=>24}; $args=['http://portal.acm.org/citation.cfm?id=']; $in='clicks.txt'; $job='target_for_site'; eval IO.read('qlm.rb')  
load 'ilab.rb'
$in  ||= ARGV[0]
$job ||= ARGV[1]
LABEL_CLICKS = [:qid,:query,:time,:url,:pos]

$data = IO.read($in).split("\n").map{|e|e.split("\t").to_hash(LABEL_CLICKS)}
case $job
when "url_pattern" #Query with many click with URL matching prefix
  url_pattern = ARGV[2] || $args[0]
  result = $data.find_all{|e|e}.find_all{|e|e[:url] =~ /#{url_pattern}/} #queries targeted for specific website

when "target_for_site" #Query with many click with URL matching prefix
  url_prefix = ARGV[2] || $args[0]
  result = []
  $data.find_all{|e|e}.group_by{|e|e[:qid]}.
    find_all{|k,v|v.all?{|e|e[:url].starts_with?(url_prefix)}}. #queries targeted for specific website
    each{|e|result.concat e[1]}
    
when "target_for_ext" #Query with many click with URL matching prefix
  file_ext = ARGV[2] || $args[0]
  result = []
  $data.find_all{|e|e}.group_by{|e|e[:qid]}.find_all{|k,v|v.size == 1}.
    find_all{|e|e[1].all?{|e2|e2[:url].ends_with?(file_ext)}}. #queries targeted for specific file type
    each{|e|result.concat e[1]}
end

File.open( "#$in.out"  , "w"){|f| f.puts  result.map{|e|e.to_arr(LABEL_CLICKS).join("\t")}.join("\n")}
