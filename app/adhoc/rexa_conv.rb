load 'ilab.rb'


# Query Log 

data = IO.read('user-queries.txt').split("\n").map{|l|l.split(/\s+/)}
result = []
user_IP = nil
user_query = nil

data.each do |l|
  if l[7] == "Query:"
    user_IP = l[6]
    user_query = l[8..-1].join(" ")
  elsif l[7] == "Request:"
    if l[6] == user_IP && l[8] =~ /paperhomepage/
      result << [user_IP, user_query, l[8]]
    end
  end
end

#File.open("rexa_data.txt", "w"){|f|f.puts result.map{|e|e.join("\t")}.join("\n")}

result_q = result.map{|e|e[1]}.uniq.map_hash_with_index{|e,i|[e,i+1]}
result_f = result.map{|e|[result_q[e[1]],0,e[2].split("/")[-1],1]}

File.open("rexa_qrel.txt", "w"){|f|
  f.puts result_f.uniq.sort_by{|e|e[0]}.map{|e|e.join(" ")}.join("\n")}

File.open("rexa_query.txt", "w"){|f|
  f.puts result_q.sort_by{|k,v|v}.map{|e|"<query id=\"#{e[1]}\"> #{e[0]} </query>"}.join("\n")}

#result.group_by{|e|e[1]}.each{|k,v|p [k,v.size] if v.size > 10} ; nil

# Collection Documents 

load 'app/ilab.rb'
$exp_root = "."
$i = ILab.new("rexa")
$i.config_path( :work_path=>$exp_root+'/rexa' )

rp = IO.read('rexa/rexa-papers.csv') ; nil

def convert_rexa_col(rp)
  rp.split("\n").each do |e| 
    begin
      line = FasterCSV.parse(e)[0]
      if line.size < 7 #line[3].to_i == 0 || 
        puts "Skipping #{line.inspect}"
        next
      end 
      #['metadata', line[4]], 
      data = [['ID', line[0]], ['title',line[2]], ['author', line[5].clear_tags(" ").gsub("%%"," ")], ['abstract', line[6..-1]]]
      data.concat line[4].split("%%").find_all{|e|e.size > 0}.map{|e|e.split("=")}
      #p data
      $engine.generate_doc("rexa/rexa_docs", line[0], data.map{|e|{:tag=>e[0], :content=>e[1]}})
    rescue Exception => e
      puts e
    end
  end
  nil
end
convert_rexa_col(rp)

