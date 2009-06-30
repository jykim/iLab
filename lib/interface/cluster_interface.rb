require 'timeout.rb'

#Run command across cluster nodes
# - nids : array of node ids
# - cmds : 
def run_cluster(nids, cmds, o={})
  o[:timeout] ||= 3
  nids.each_with_index do |nid, i|
    thr = Thread.new do
      Thread.current[:nid] = nid
      Thread.current[:idx] = i
      s = nil
      begin
        timeout(o[:timeout]) do
          cmd = (cmds.class == String)? cmds : cmds[i]
          s = `ssh #{nid} '#{cmd}'`
        end
      rescue TimeoutError
        puts "Timeout #{nid}(#{i})"
      end#begin
      s
    end#thread
  end
  
  #Collect results
  results = []
  Thread.list.each_with_index do |t,i|
    if t == Thread.main then next end
    t.join
    result = [t[:nid], t.value, t[:idx]]
    if t[:nid] && t.value
      if block_given?
        yield *result
      end
      results << result
    end
  end
  results
end


#Find nodes to submit jobs
# [[node_id1, node_uptime, node_index],... ] (ordered by uptime)
def get_anodes()
  nodes = [] ; 1.upto(32){|i|nodes << "compute-0-#{i}"}
  run_cluster(nodes, "uptime").map{|e|[e[0], e[1].scan(/\d\.\d\d/)[0].to_f, e[2]]}.sort_by{|e|e[1]}  
end

# Perform split cmd
# - return : an array of output files
def run_split(input_file, prefix, o={})
  result = get_split_files(input_file, prefix)
  if result.size > 0
    puts "[run_split] result exists. skipping..."
    return result
  end
  o[:suf_len] ||= 5
  if o[:k]
    o[:line_bytes] = (File.size(input_file) / o[:k].to_f).to_i
    o[:suf_len] = Math.log10(o[:k]).ceil
  end
  #split argument
  arg = if o[:line_bytes]
    "-C #{o[:line_bytes]}"
  elsif o[:lines]
    "-l #{o[:lines]}"
  end
  log = `split #{arg} -d -a #{o[:suf_len]} #{input_file} #{prefix}`
  if log.scan(/[a-z]/).size > 0
    puts "[run_split] error[#{log}]"
    return nil
  end
  get_split_files(input_file, prefix)
end

def get_split_files(input_file, prefix)
  traverse_path(File.dirname(input_file), :filter=>/^#{prefix}[0-9]+$/)
end
