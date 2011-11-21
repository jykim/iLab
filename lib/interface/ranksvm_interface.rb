module RanksvmInterface
  def generate_input_ranksvm(cand_set, file_name)
    File.open(file_name, 'w') do |f|
      cand_set.map_with_index{|cand,i|
        cand.map_with_index{|c,j|
          f.puts "#{(j==0)? 2 : 1} qid:#{i+$offset} #{c[1..-1].map_with_index{|e,k|"#{k+1}:#{e}"}.join(" ")} # #{c[0]}"
          }
        }
    end
  end
  
  # RansSVM input file => candidate set array
  def parse_input_ranksvm(file_name)
    IO.read(file_name).split(/^(?=2)/).map{|cand|
      cand.split("\n").map{|l|
          l.split(" ")[1..($features.size+1)].map{|e|e.split(":")[1]}
        }
    }
  end
  
  def run_ranksvm(filename, o={})
    cmd = "#{ENV['SVMRANK']}/svm_rank_learn -c #{o[:tradeoff] || 8} #{filename} #{filename}.out >& /dev/null "
    #puts cmd
    system(cmd)
    weights = (1..$features.size).to_a.map_hash{|e|[e, 0.0]}
    IO.read("#{filename}.out").split("\n")[-1].split(" ")[1..-2].map{|e|
      weights[e.split(":")[0].to_i] = e.split(":")[1].to_f}
    weights.sort_by{|k,v|k}.map{|e|e[1]}
  end
  
  def train_parameter(filename, o = {})
    params = (-5..5).to_a.map{|e|(e >= 0) ? 2 ** e : (1.0 / (2 ** -e))}
    files = gen_cval_files(filename, o[:folds] || 5, :random_split=>true)
    params.map_hash do |param|
      results = files.map do |file|
        weights = run_ranksvm(file+".train", :tradeoff=>param)
        cand_set = parse_input_ranksvm(file+".test")
        #puts "  weights = #{weights.inspect} / testset = #{cand_set.map{|cand|cand[0][0]}.inspect}"
        evaluate_cand_set(cand_set, weights).mean
      end
      #puts "[train_parameter] param: #{param} results: #{results.avg} <= #{results.inspect}"
      [param, results.avg]
    end
  end
  
  def gen_cval_files(filename, folds, o = {})
    data = IO.read(filename).split(/^(?=2)/)
    raw_data = (0...data.size).to_a
    raw_data = raw_data.shuffle if o[:random_split]
    test_sets= raw_data.in_groups_of((data.size.to_f / folds.to_f).floor)
    #debugger
    #puts ((0...data.size).to_a - test_sets[0..(folds.to_i-1)].flatten)
    (raw_data - test_sets[0...(folds.to_i)].flatten).
      each_with_index{|e,i|test_sets[i] << e if e}
    #p test_sets
    results = []
    1.upto(folds.to_i) do |i|
      puts "#{test_sets[i-1].size} / #{data.size}"
      results << split_file("#{filename}-k#{folds}-#{i}", data, 
        :random=>o[:random_split], :test_set=>test_sets[i-1])
    end
    results
  end
  
  def split_file(filename, data, o={})
    result_train, result_test = [], []#[o[:header]], [o[:header]]
    data.each_with_index do |e,i|
      #puts rand(), train_ratio
      if o[:test_set]
        if !o[:test_set].include?(i)
          if o[:train_ratio] && (o[:random] ? rand() : i.to_f / data.size) > o[:train_ratio].to_f
            next
          else
            result_train << e
          end
        else
          result_test << e
        end
      elsif o[:train_ratio]
        if (o[:random] ? rand() : i.to_f / data.size) >= o[:train_ratio].to_f
          result_test << e
        else
          result_train << e
        end
      else
        puts "[split_file] No parameter specified!"
      end
    end
    File.open(filename+"#{o[:train_ratio]}.train",'w'){|f|f.puts result_train.find_valid.join}
    File.open(filename+"#{o[:train_ratio]}.test" ,'w'){|f|f.puts result_test.find_valid.join}
    filename
  end
end