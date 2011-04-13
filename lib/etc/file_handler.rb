
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
      #puts "#{fp} started..."
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
#def batch_rename(path , ptn_fr, ptn_to, o={})
#  traverse_path(path, o.merge(:filter=>ptn_fr)) do |fp,fn|
#    puts cmd = "mv #{fp} #{File.join(File.dirname(fp), fn.gsub(ptn_fr,ptn_to))}"
#    `#{cmd}` if o[:commit]
#  end
#  nil
#end
#
#
#def batch_edit(path , o = {})
#  new_path = o[:new_path] || 'tmp'
#  begin
#    Dir.mkdir( new_path ) if !File.exist?( new_path ) &&  !o[:skip_output]
#    traverse_path(path, o) do |fp,fn|
#      new_file = File.join(new_path , fn)
#      while File.exists?(new_file)
#        #puts "[batch_edit] Duplicated Filename : #{new_file}"
#        if (no = new_file.scan(/\[([0-9]+)\]/)).size == 0
#          new_file = new_file[0..-5] + '[1].xml'            
#        else
#          new_file = new_file.gsub!("[#{no[-1][0]}]" , "[#{no[-1][0].to_i+1}]")
#        end
#      end
#      result = yield new_file, IO.read(fp)
#      File.open(new_file, 'w'){|f| f.puts result} if !o[:skip_output]
#      puts "#{fn} finished..."
#    end
#  rescue SystemCallError
#    $stderr.print "[batch_edit] IO failed: " + $! + "\n"
#  end
#end
