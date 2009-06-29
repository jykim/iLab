# Script for Simulated Deskto Collection Generation
#
# < Document Extraction from TREC collection >
# $o = {:ext_doc=>true} ; eval IO.read('pd_build.rb')
#
# < Dcoument Gathering by Yahoo API >
# $o = {:pid=>['c0002','c0141','c0161']} ; eval IO.read('pd_build.rb')
#
DEFAULT_ENGINE_TYPE = :indri
load 'ilab.rb'
load 'adhoc/pd_lib.rb'

$engine = IndriInterface.new

#Build {pID=>[name,email]}
if !defined?(dph)
  pdh = {}
  dpa = IO.read('tmp/IdentifiedExpertList.txt').split("\n").map{|e|e.split(" ")}
  #Build {dID=>[pID1,pID2]}
  dph = dpa.map_hash{|l|[l[0] , l.find_all{|e|e=~/^cand/}.uniq]}
  #Build {pID=>{dID=>count, ...}, ...}
  dpa.each do |l|
    l.find_all{|e|e=~/^cand/}.each do |e|
      pdh[e] = {} if !pdh[e]
      (pdh[e][l[0]])? pdh[e][l[0]] += 1 : pdh[e][l[0]] = 0
    end
  end
  puts pdh.size.to_s + " records read"
end

if $o[:ext_doc]
  #Extract documents and organize by person ID
  Find.find(TREC_LIST_COL_PATH) do |fp|
    next if FileTest.directory?(fp)
    puts "#{fp} started..."
    IO.read(fp).scan(/\<DOC\>.*?\<\/DOC\>/m).each do |doc|
      did = doc.scan(/\<DOCNO\> (.*?) \<\/DOCNO\>/)[0][0]
      if !dph[did] || dph[did].size < 1
        #puts "did/pid not found"
        next
      end
      dph[did].each do |pid|
        puts "Document #{did} for #{pid}"
        path = File.join(PD_COL_PATH,"#{pid.sub(/candidate/,"c")}/lists_doc")
        Dir.mkdir(path) if !File.exist?(path)
        File.open(File.join(path,"#{did}.html"), "w"){|f|f.puts doc}
      end
    end
  end
end

if !defined?(pa)
  ### PERSON-NAME
  # {pID=>[name, email]
  pnh = IO.read('tmp/ent05.expert.candidates').split("\n").map_hash do |e|
    a = e.split(" ")
    [a[0].split("-").join , [a[1..-2].join(" ") , a[-1]]]
  end

  ### PERSON-TOPIC
  qr5 = IO.read('tmp/ent05.expert.qrels').split("\n").map{|e|e.split(" ")}
  qr6 = IO.read('tmp/ent06.qrels.expert').split("\n").map{|e|e.split(" ")}
  t5  = IO.read('tmp/ent05.expert.topics').scan(/\<title\>(.*?)\<\/title\>/).flatten
  t6  = IO.read('tmp/ent06.expert.topics').scan(/\<title\>(.*?)\<\/title\>/).flatten

  #Build {tID=>topic, ...}
  i = 0 ; th = t5.concat(t6).map_hash{|e|i += 1 ; [i , e]}

  #Build {pID=>[topic1, topic2,...], ...}
  qra = qr5.concat(qr6).find_all{|e|e[3] != "0"}
  pth = qra.group_by{|e|e[2]}.map_hash{|k,v|[k.split("-").join,v.map{|e|th[e[0].to_i]}]}

  ### REPORT for Top 20
  # [pid, [name,email], [topic1,topic2,...], [type1=>num_docs,...]]
  pa = []
  File.open("pd_report.txt", "w") do |f|
    pa = pdh.sort_by{|k,v|v.size}.reverse[0..19].map{|e|[e[0], pnh[e[0]] , pth[e[0]], 
      e[1].group_by{|k,v|k.split("-")[0]}.map{|k,v|[k,v.size]}.sort_by{|e|e[1]}.reverse]}
    pa.each do |e|
      f.puts e.map{|e2|e2.inspect}.join("|")
    end
  end
end

# Add docs by Web Search
require 'cgi'
yi = YahooInterface.new
pa.each_with_index do |e,i|
  pid = e[0].sub(/candidate/,"c")
  if $o[:pid] && !$o[:pid].include?(pid) then next end
  write_topic(File.join(PD_PATH,"topic_#{e[0]}"), e[2].map{|e2|{:title=>e2}})
  ($o[:col_type] || ['html','pdf','msword','ppt']).each do |type|
    e[2][0..9].each do |topic|
      yi.search( CGI.escape(topic), :out_path=>File.join(PD_COL_PATH, pid), :type=>type)
    end
  end
end
