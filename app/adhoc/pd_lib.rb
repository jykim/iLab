TREC_PATH = "/work1/jykim/prj/dih/trec/"
TREC_COL_PATH = "/work1/jykim/prj/dih/trec/raw/"
TREC_LIST_COL_PATH = "/work1/jykim/prj/dih/trec/lists/"
PD_PATH = "/work1/jykim/prj/dih/pd"
PD_COL_PATH = "/work1/jykim/prj/dih/pd/raw"
TEXT_CONV_PATH = "java -jar /work1/jykim/app/apache-tika-0.3/target/tika-0.3-standalone.jar -t"
COL_TYPES = ['msword','ppt','pdf','lists','html']
FIELD_EMAIL = ['subject','content','to','sent','name','email']
FIELD_ETC = ['title','url','abstract','date','text']
PIDS = ['c0161','c0002','c0141']
TOPIC_TYPES = ['F_RN_TIDF','F_RN_TF','F_RN_IDF','F_RN_RN','D_TF','D_TIDF','D_IDF','D_RN']
CS_TYPES = [:uniform, :cql,:mpmax, :mpmean]#[:cql]
NORM_TYPES = [:none, :minmax] #[:minmax]
MERGE_TYPES = [:cori, :multiply]
#TOPIC_TYPES = ['F_subject_TF','F_text_TF','F_title_TF','F_text_TF']

# Convert a binary document to text
def conv_text(path , ext)
  case ext
  when 'html'
    `cp #{path} #{path}.txt`
  else
    `#{TEXT_CONV_PATH} #{path} > #{path}.txt`
  end
  if File.stat("#{path}.txt").size > 0
    true
  else
    warn "[conv_text] conversion for #{path} failed!"
    false
  end
end

def to_ext(col_type)
  case col_type
  when 'msword' : 'doc'
  when 'xl' : "xls"
  else col_type
  end
end

# Generate document with metadata from the collection
def create_doc(path , doc_id , o = {})
  `mkdir -p #{path}` if !File.exist?(path)
  template = ERB.new(IO.read(to_path("doc_pd.rxml")))
  File.open("#{path}/#{doc_id}.xml", "w"){|f| f.puts template.result(binding)}
  puts "[create_doc] #{doc_id} file created"
end

# Clean-up non-ascii files in collection
def cleanup_doc(path)
  #batch_edit(path, :new_path=>path) do |fname, contents|
  #  contents.remove_nonascii
  #end
  `cp -r #{path} #{path}_0116`
  traverse_path(path, :filter=>/xml$/) do |fp,fn|
    content  = IO.read(fp)
    `iconv -t ascii #{fp} >& cleanup_doc.tmp`
    if !content.find_tag('DOCNO').first || IO.read('cleanup_doc.tmp').scan("illegal input sequence").size > 0
      puts "Eliminate #{fp}"
      #`rm #{fp}`
    end
  end
end

#Verify index for docs without doc_id
def verify_index(index_path)
  1.upto($engine.get_col_stat()[:doc_no]) do |i|
    puts "#{i} : "+`dumpindex #{index_path} dn #{i}`
  end
end

#Filter result document with valid form
def filter_result_file(file_name)
  s = IO.read(file_name).split("\n") 
  s_new = s.find_all{|l|l.split(/\s+/).size > 5}
  info "[filter_result_file] inconsistent result was filtered!" if s.size != s_new.size
  File.open(file_name,'w'){|f|f.puts s_new.join("\n")}
end

def list_index_info
  PIDS.each do |pid|
    COL_TYPES.each do |col_type|
      s = `dumpindex pd/index_#{pid}_#{col_type} s`
      a = s.split("\n").map{|l|l.split(/:\s+/)}
      puts "#{pid}\t#{col_type}\t#{a[1][1]}\t#{a[2][1]}\t#{a[3][1]}"
    end
  end
end

# < Performance & MP summary from knownitem experiment output >
def ki_perf_summary(input_file)
  s = IO.read(input_file)
  method_type=['DQL','PRM']
  s.split("\n").each do |l|
    e = l.split("|")
    puts [PIDS.pfind(e[0]), COL_TYPES.pfind(e[0]), TOPIC_TYPES.pfind(e[0])].concat(e[2..-1]).join("|")
  end
  nil
end

# Get the ratio of documents from the relevant collection
# get_col_ratio("c0161_all_F_RN_IDF_0318c", "DQL")
def analyze_col_ratio(topic_id , method, o = {})
  topk = o[:topk] || 50
  begin
    col_ptns = ['lists','html','pdf','msword','ppt']
    #{qid=>{type1=>[[qid1,type1],[qid2,type2]], type2=>}}
    res = IO.read("query/#{topic_id}_#{method}.res").split("\n").map{|e|a = e.split(" ") ; [a[0], col_ptns.pfind(a[2])]}.
        group_by{|e|e[0]}.map_hash{|k,v|[k,v[0..topk].group_by{|e|e[1]}]}
    res_max_col = res.map_hash{|k,v|[k,v.sort_by{|k2,v2|v2.size}[-1][0]]}
    qrel = IO.read("qrel/qrel_#{topic_id}").split("\n").map{|e|a = e.split(" ") ; [a[0], col_ptns.pfind(a[2])]}

    count = qrel.sort_by{|e|e[0].to_i}.map{|e| (e[1] == res_max_col[e[0]])? 1 : 0 }.sum#puts "#{e[0]} #{e[1]} #{res_max_col[e[0]]}" ;
    res_rel_ratio = res.map{|k,v|r = v.map_hash{|k2,v2|[k2,v2.size]}.to_p[qrel.to_h[k]] ; (r)? r : 0}.avg
    puts "#{topic_id} #{method} #{count} #{res_rel_ratio}"
  rescue Exception => e
    puts e
  end
end

# Analyze the collection score accuracy
#  analyze_col_score('c0161_all_F_RN_RN_0318d','pd@perf@meta_cql@0402@col_type,all-pid,c0161-topic_id,F_RN_RN_0318d.log)
def analyze_col_score(qrel_name, file_name)
  col_ptns = ['lists','html','pdf']
  input = []
  col_ptns.each do |col_type|
    input.concat IO.read(file_name.sub("all",col_type)).split("\n").map{|e|a = e.split(/\s+/) ; [col_ptns.pfind(a[0]), a[1], a[2]]}
  end
  #{qid=>[type1=>score1,...]}
  res = input.group_by{|e|e[1]}.map_hash{|k,v|[k,v.map{|e|[e[0],Math.exp(e[2].to_f)]}.to_p.sort_by{|e|e[1]}]}
  qrel = IO.read(qrel_name).split("\n").map_hash{|e|a = e.split(" ") ; [a[0], col_ptns.pfind(a[2])]}
  count = qrel.sort_by{|k,v|k.to_i}.map{|e|puts "#{e[0]} #{e[1]} #{res[e[0]][-1][0]}" ; (e[1] == res[e[0]][-1][0])? 1 : 0 }.sum ; #
  ratio = res.map{|k,v|v.to_h[qrel[k]]}.avg
  info "[analyze_col_score] Accuracy: #{count}/50 Ratio: #{ratio}"
  res
end
