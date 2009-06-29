SEP_1 = "@"
SEP_2 = "-"
SEP_3 = "," 

#Assign System-wide Default Parameters
def get_opt_ilab(o_arg = {})
  o = {}
  
  #Collection Parameter
  o[:bucket_size] = 100
  o.merge(o_arg)
end

def factory( class_name , *args )
  class_name.new(*args)
end

def info(str , file_name = nil)
  puts str
  $i.fwrite(file_name, str, :mode=>'a') if $i && file_name
  $lgr.info str if $lgr
end

def error(str)
  err(str)
end

def debug(str)
  dbg(str)
end

def err(str)
  puts str
  $lgr.error str if $lgr
end

def dbg(str)
  puts str
  $lgr.debug str if $lgr
end

#Execute ILab as external process & get returned value as Hash
PTN_RET_VAL = /RETURN\<(.*?)\>RETURN/
def run_ilab(prj, expid , arg1 = nil , o = {})
  if File.exist?(to_path("#{expid}.log")) && 
      (ret_val = IO.read(to_path("#{expid}.log")).scan(PTN_RET_VAL)).size == 1
    info "[run_ilab] Result found - read : #{expid} #{ret_val.inspect}"
  else
    #puts "File Not Found #{to_path("#{expid}.log")}"
    cmd = "#{RUBY_CMD} #{$ilab_root}/ilab/run_#{prj}.rb \"#{expid}\""
    cmd += " \"#{arg1}\"" if arg1
    if o[:remote]
      cmd = "ssh #{o[:nid]} 'source ~/.bash_profile;#{cmd}'"
    end
    $i.fwrite('cmd_run_ilab.log' , cmd , :mode=>'a')
    info "[run_ilab] Started #{(o[:remote])? 'at '+o[:nid] : ''}  : #{expid}\n"
    ret_val = $i.fwrite("run_ilab.log", `#{cmd}`).scan(PTN_RET_VAL)
    raise ExternalError , cmd if ret_val.size != 1
    info "[run_ilab] Finished : #{expid}"# #{ret_val.inspect}"
  end
  eval(ret_val[0][0])
end

#Calculate range that suits for given topic and cross validation setting
# ex) 0.upto(3) {|i| p get_cval_range(1 , 100 , 4 , i)}
#     1..25 / 26..50 / 51..75 / 76..100
def get_cval_range(t_offset , t_count , cval_no , cval_id)
  (t_offset+(t_count/cval_no)*cval_id)..(t_offset+(t_count/cval_no)*(cval_id+1)-1)
end

#Generate experiment id from current envronment
def get_expid_from_env(o = {})
  #puts "[get_expid_from_env] #{$method}"
  code = [(o[:col] || $col) , (o[:exp] || $exp) , (o[:method] || $method) , (o[:remark] || $remark)].join(SEP_1)
  o = $o if o.size == 0
  if o.size > 0
    code += (SEP_1 + o.find_all{|k,v|v}.map{|e|[e[0],((e[1].class==Symbol)? ":" : "")+e[1].to_s.to_fname].join(SEP_3)}.join(SEP_2)) 
  else
    code += SEP_1
  end
end

def get_env_from_expid(expid)
  expid.split(SEP_1).each_with_index do |e,i|
    case i
    when 0 : $col = e
    when 1 : $exp = e
    when 2 : $method = e
    when 3 : $remark = e
    when 4
      $o = e.split(SEP_2).map_hash{|e|[e.split(SEP_3)[0].to_sym , e.split(SEP_3)[1].to_num]}
    end
  end
  info("[get_env_from_expid] $col='#{$col}'; $exp='#{$exp}'; $method='#{$method}'; $o=#{$o.inspect}; $remark='#{$remark}'; eval IO.read('run.rb')")
end

#Find file in path using pattern
def find_file(path, pattern = /.*/)
  puts "!"
  result = []
  Dir.entries(path).each do |fn| 
    #puts fn
    result << fn if fn =~ pattern
  end
  (result.size > 1)? result : result.first
end

#Get appropriate full path based on file name
def to_path(file_name , arg_path = nil)
  path = arg_path || $work_path || "."
  result = case file_name
           when /^exp_.*\.(rhtml|rb)/ #experiment-specific source
             File.join( $ilab_root , "ilab/exp/#{file_name}")
           when /\.(rhtml|rxml|template)/
             File.join( $ilab_root , "ilab/template/#{file_name}")
           when /\.R/
             File.join( $ilab_root , "ilab/interface/#{file_name}")
           when /\.(css|js)/
             File.join( $ilab_root , "ilab/template/#{file_name}")
           when /^qrel_.*/
             File.join( path , "qrel/#{file_name}")
           when /^topic_.*/
             File.join( path , "topic/#{file_name}")
           when /doc_.*/
             File.join( path , "doc/#{file_name}")
           when /^(img|rpt|qry|data).*/
             path_rpt = File.join( path , "rpt/#{get_expid_from_env()}")
             (File.exists?(path_rpt))? `touch #{path_rpt}` : Dir.mkdir( path_rpt )
             File.join( path , "rpt/#{get_expid_from_env()}/#{file_name}")
           when /\.(prior|txt|out|doclist|qrel)$/
             File.join( path , "out/#{file_name}")
           when /\.(in)/
             File.join( path , "in/#{file_name}")
           when /\.(qry|res|eval)/
             File.join( path , "query/#{file_name}")
           when /\.(log|err)/
             File.join( path , "log/#{file_name}")
           when /\.(dmp)/
             File.join( path , "dmp/#{file_name}")
           when /\.(tmp)/
             File.join( path , "tmp/#{file_name}")
           when /\.(plot)/
             File.join( path , "plot/#{file_name}")
           else
             File.join( path , file_name )
           end
  #puts "[to_path] #{result}"
  result
end
  
def get_rpt_filepath(exp_id)
  "#{exp_id}/rpt_#{exp_id}.html"
end

def get_log_filepath(exp_id)
  "../log/#{exp_id}.log"
end

require 'find'
def traverse_path(path, o={})
  result = []
  if o[:recursion]
    Find.find(path) do |fp|
      puts "#{fp} started..."
      fn = File.basename(fp)
      if FileTest.directory?(fp)
        if fn[0] == ?.
          Find.prune       # Don't look any further into this directory.
        else
          next
        end
      else
        next if o[:filter] && !(o[:filter] =~ fn)
        if block_given?
          yield fp,fn
        else
          result << fp
        end
      end
    end
  else
    Dir.entries(path).each do |fn|
      fp = File.join(path, fn)
      next if ['.','..'].include?(fn) || (o[:skip_dir] && File.directory?(fp)) || (o[:filter] && !(o[:filter] =~ fn))
      if block_given?
        yield fp,fn
      else
        result << fp
      end
    end
  end
  result
end

# Perform batch rename
# e.g. batch_rename('.',/candidate([0-9]+)/,"c\\1", :commit=>true)
def batch_rename(path , ptn_fr, ptn_to, o={})
  traverse_path(path, o.merge(:filter=>ptn_fr)) do |fp,fn|
    puts cmd = "mv #{fp} #{File.join(File.dirname(fp), fn.gsub(ptn_fr,ptn_to))}"
    `#{cmd}` if o[:commit]
  end
  nil
end


def batch_edit(path , o = {})
  new_path = o[:new_path] || 'tmp'
  begin
    Dir.mkdir( new_path ) if !File.exist?( new_path ) &&  !o[:skip_output]
    traverse_path(path, o) do |fp,fn|
      new_file = File.join(new_path , fn)
      while File.exists?(new_file)
        #puts "[batch_edit] Duplicated Filename : #{new_file}"
        if (no = new_file.scan(/\[([0-9]+)\]/)).size == 0
          new_file = new_file[0..-5] + '[1].xml'            
        else
          new_file = new_file.gsub!("[#{no[-1][0]}]" , "[#{no[-1][0].to_i+1}]")
        end
      end
      result = yield new_file, IO.read(fp)
      File.open(new_file, 'w'){|f| f.puts result} if !o[:skip_output]
      puts "#{fn} finished..."
    end
  rescue SystemCallError
    $stderr.print "[batch_edit] IO failed: " + $! + "\n"
  end
end

#Get Smoothing Parameter
def get_sparam(method, param_value , field = nil, operator = 'term')
  IndriInterface.get_sparam(method, param_value , field, operator)
end

#Get Smoothing Parameter
def get_sparam2(method, param_hash , field = nil, operator = 'term')
  IndriInterface.get_sparam2(method, param_hash , field, operator)
end

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

