#Sorting by Reverse of Column
s = IO.read('englishpast.csv')
r =  s.split("\r").map{|l|l.split(',')}.
       find_all{|e|e.size>3}.sort_by{|e|e[2].reverse}.
       map{|e|e.join(",")}.join("\n")
File.open('englishpast_sort.txt','w'){|f|f.puts r}
