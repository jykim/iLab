
class LDAInterface
  attr_reader :engine
  def initialize()
  end
  
  def prepare(index_path, doc_count)
    @engine = IndriInterface.new("", :index_path=>index_path)
    File.open("#{File.basename(index_path)}.lda","w") do |f|
      f.puts doc_count
      1.upto(doc_count) do |i|
        s = @engine.get_index_info("dv" , i)
        f.puts s.split("\n").map{|e|e.split(" ")[2]}.find_all{|e|e=~/^[a-z]+$/ && e.size > 2}[0..200].join(" ")
      end
    end
  end
end
