require 'find'
require 'ilab.rb'
extensions = ['tex','pdf','html','htm','xls','xlsx','ppt','doc','pptx','docx']

def find_path(path, o = {})
  result = []
  Find.find(path) do |fp|
    fn = File.basename(fp)
    if FileTest.directory?(fp)
      puts "#{fp} started..."
    else
      if block_given?
        yield fp,fn
      elsif fp =~ /\.(#{o[:extensions].join('|')})$/i
        result << [fp,File.stat(fp).size]
      end
    end
  end
  result
end

r = find_path("/Users/lifidea/Documents", :extensions=>extensions)
puts r.map{|e|e.join("\t")}.join("\n")
puts r.group_by{|e|File.basename(e[0]).scan(/\.#{extensions.join('|')}$/i)}.map{|k,v|[k,v.size].join("\t")}.join("\n")
