load 'app/ilab.rb'
$exp_root = "."
$i = ILab.new("twir")
$i.config_path( :work_path=>$exp_root+'/twir' )


def convert_twir_col(filename)
  File.open(filename,"r") do |f|
    File.open(filename+'.filter',"w") do |of|
      while line = f.gets
        begin
          l = line.split("\t")
          data = [["content",l[2]], ["qtime",l[0]]]
          of.puts $engine.generate_doc("twir/twir_docs", l[5], data.map{|e|{:tag=>e[0], :content=>e[1]}}, :as_string=>true)
        rescue Exception => e
          puts e
        end
      end
    end
  end
end

convert_twir_col("twir/20110123_20110208.eng.twitter")

def filter_twir_col(filename, dict)
  File.open(filename,"r") do |f|
    File.open(filename+'.filter',"w") do |of|
      while line = f.gets
        begin
          next if !dict[line.split("\t")[5]]
          of.puts line
        rescue Exception => e
          puts e
        end
      end
    end
  end
end

qrel_dict = IO.read("tweets.qrels2").split("\n").map_hash{|e|[e,1]}
filter_twir_col("20110123_20110208.eng.twitter", qrel_dict)

def convert_twir_topic(filename)
  dt = IO.read(filename).split("\n").map{|e|e.split("\t")}
  result = dt.map do |l|
    [l[0], l[1], Time.parse(l[4]).strftime("%Y%m%d%H%M%S")]
  end 
  File.open(filename+".qry", "w"){|f|f.puts result.map{|e|"<qid>#{e[0]}</qid>\n<query>#{e[1]}</query>\n<qtime>#{e[2]}</qtime>\n"}.join("\n")}
end

convert_twir_topic("topic_twir_all.raw")
