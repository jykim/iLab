
# Build trec-topic 
# - topics [{:title=>'title', ...}, ...]
def write_topic(file , topics , o={})
  return if File.exist?(file)
  o[:template] = :trec if !o[:template] #assign default template
  o[:template] = to_path("topic_#{o[:template].to_s}.rhtml") if o[:template].class == Symbol
  template = ERB.new(IO.read(o[:template]))
  File.open(file, "w"){|f|f.puts template.result(binding)}
end

#Merge Judgments in file_in to file_out
# - output qrel is sorted by qid, did
def update_qrel(file_in, file_out)
  h_in, h_out = read_qrel(file_in), read_qrel(file_out)
  #p h_in
  h_out.each do |k,v|
    v.each{|k2,v2| h_out[k][k2] = h_in[k][k2] if h_in[k][k2]}
  end
  `cp #{file_out} #{file_out}.bak`
  write_qrel(file_out, h_out)
end

#h = {qid1=>{did1=>rel1, ...}, ...}
def write_qrel(file, h)
  h_out = []
  h.map{|k,v| h_out.concat v.map{|k2,v2|[k,0,k2,v2]}}
  File.open(file, "w"){|f|f.puts h_out.sort_by{|e|[e[0].to_i, e[2]]}.map{|e|e.join(" ")}.join("\n")}
end

#Read Qrel file into {qid1=>{did1=>rel1, ...}, ...}
def read_qrel(file)
  h = {}
  IO.read(file).split("\n").each do |l|
    a = l.split(" ")
    h[a[0]] = {} if !h[a[0]]
    h[a[0]][a[2]] = a[3]
  end
  h
end

def check_qrel(file)
  h = read_qrel(file)
  h.each do |k,v|
    v.each do |k2,v2|
      #puts "#{k}, #{k2}, #{v2}"
      v_new = yield k, k2, v2
      h[k][k2] += v_new if v_new
    end
  end
  write_qrel(file+".new", h)
end
