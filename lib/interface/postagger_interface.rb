POS_PATH = ENV['POSTAG']
MODEL_FILE = "models/bidirectional-distsim-wsj-0-18.tagger"

def run_postagger(input_file, o = {})
  cmd = "java -mx500m -cp '#{POS_PATH}/stanford-postagger.jar:' edu.stanford.nlp.tagger.maxent.MaxentTagger -model #{POS_PATH}/#{MODEL_FILE} -textFile #{input_file} > #{input_file}.out"
  #puts cmd
  system(cmd) if !File.exists?("#{input_file}.out") || o[:force] == true
  IO.read("#{input_file}.out").split("\n")
end

# Train transition probability from relevant documents
def train_trans_probs(pos_queries)
  trans = {}
  pos_queries.each do |query|
    # Parse and remove the period.
    query_pos = query.split(/\s+/).map{|e|e.split("_")[1]}[0..-2]
    ["START",query_pos,"END"].flatten.each_cons(2) do |e|
      curf, nextf = e[0], e[1]
      trans[curf] = Hash.new(0) if !trans[curf] 
      #puts "[train_trans_probs] #{curf}->#{nextf}"
      trans[curf][nextf] += 1
    end
  end
  trans
end
