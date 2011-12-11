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

#Get appropriate full path based on file name
def to_path(file_name , arg_path = nil)
  path = arg_path || $work_path || "."
  result = case file_name
           when /^exp_.*\.(rhtml|rb)/ #experiment-specific source
             File.join( $ilab_root , "app/experiments/#{file_name}")
           when /\.(rhtml|rxml|erb|template)$/
             File.join( $ilab_root , "lib/template/#{file_name}")
           when /\.R/
             File.join( $ilab_root , "lib/interface/#{file_name}")
           when /\.(css|js)/
             File.join( $ilab_root , "lib/template/#{file_name}")
           when /^qrel_.*/
             File.join( path , "qrel/#{file_name}")
           when /\.(in|stem)/
             File.join( path , "in/#{file_name}")
           when /^topic_.*/
             File.join( path , "topic/#{file_name}")
           when /doc_.*/
             File.join( path , "doc/#{file_name}")
           when /^(img|rpt|qry|data).*/
             path_rpt = File.join( path , "rpt/#{get_expid_from_env()}")
             (File.exists?(path_rpt))? `touch #{path_rpt}` : Dir.mkdir( path_rpt )
             File.join( path , "rpt/#{get_expid_from_env()}/#{file_name}")
           when /\.(prior|out|doclist)$/
             File.join( path , "out/#{file_name}")
           when /\.(qry|res|eval)/
             File.join( path , "query/#{file_name}")
           when /\.(log|err)/
             File.join( path , "log/#{file_name}")
           when /\.(trecweb|trectext)$/
             File.join( path , "raw_doc/#{file_name}")
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
