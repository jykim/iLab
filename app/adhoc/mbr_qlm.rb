

def get_query_stat( file , ofile = nil )
  File.open( file ) do |f|
    File.open( (ofile || file+'.out') , 'w' ) do |of|
      of.puts ["length", "quote", "bAND", "bOR", "bNOT", "plus", "minus", "field", "range", "fuzzy", "qry"].join("\t")
      while line = f.gets
        begin
          qry = line.split("\t")[2]
          length = qry.split(/\s+/).size
          quote = qry.scan("\"").size
          bAND = qry.scan(/\sAND\s/).size
          bOR = qry.scan(/\sOR\s/).size
          bNOT = qry.scan(/\sNOT\s/).size
          plus = qry.scan(/(^|\s)\+\S/).size
          minus = qry.scan(/(^|\s)\-\S/).size
          field = qry.scan(/[a-zA-Z]+\:\S+/).find_all{|e| !e.include?("http:") && !e.include?("cache:")  }.size
          range = qry.scan(/\[.*?TO.*?\]/).size
          fuzzy = qry.scan(/\S\~($|\s)/).size

          of.puts [length, quote, bAND, bOR, bNOT, plus, minus, field, range,  fuzzy, qry].join("\t")
        rescue Exception => e
          puts "Error in [#{line}]"
        end
      end
    end
  end
end

#get_query_stat("query-click-sessions.tsv")

get_query_stat "log_hf/openlib/query-click-sessions.tsv", "query-click-sessions.tsv.stat"


awk 'BEGIN{FS="\t"}{print $1,"\t",$2,"\t",$3,"\t",$4,"\t",$5,"\t",$6,"\t",$7,"\t",$8,"\t",$9,"\t",$10}' query-click-sessions.tsv.stat > query-click-sessions.tsv.stat.only

awk 'BEGIN{FS="\t"}{print $1,"\t",$2,"\t",$3,"\t",$4,"\t",$5,"\t",$6,"\t",$7,"\t",$8,"\t",$9,"\t",$10}' query-click-sessions.tsv.stat > query-click-sessions.tsv.stat.only
