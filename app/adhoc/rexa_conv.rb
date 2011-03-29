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

File.open("rexa_data.txt", "w"){|f|f.puts result.map{|e|e.join("\t")}.join("\n")}

#result.group_by{|e|e[1]}.each{|k,v|p [k,v.size] if v.size > 10} ; nil

# Collection Documents 

