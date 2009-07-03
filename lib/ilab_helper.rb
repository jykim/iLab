module ILabHelper
  def apply_ordering(arr , o)
    o[:rlimit] = 100 if !o[:rlimit]
    arr = arr.reverse if o[:desc]
    if o[:limit]
      arr[0..(o[:limit]-1)]
    elsif o[:rlimit] && arr.size > o[:rlimit]
      arr[(arr.size-o[:rlimit])..(arr.size-1)]
    else
      arr
    end
  end

  def enclose(var)
    if var.class == String
      "\"#{var}\""
    else
      var
    end
  end
private
end

module ReportHelper
  HTML_HEADER = "<link href=\"print.css\" rel=\"Stylesheet\" media=\"screen\" type=\"text/css\" />\n"
  def get_html_page(content)
    s = "<html><head><title>iLab Report for #{$col} Collection</title>"
    s += "<script src=\"../../sorttable.js\"></script>"
    s += "<style type=\"text/css\">\n"
    s += IO.read(to_path('print.css'))
    s += "</style>\n</head>\n"
    s += "<body>\nClick column headings for sorting. (<a href='http://www.lifidea.com/file/ilab.pdf'>about iLab</a> / <a href='http://lifidea.com/entry/iLab-A-Platform-for-IR-Experiment'>my blog post</a>)<br>#{content}\n</body>"
  end
  
  def create_report(binding , o = {})
    puts 'Creating Report...'
    template = o[:template_str] || ERB.new(prepare_html(IO.read(o[:template] || to_path('exp_' + $exp + '.rhtml' ))))
    rpt_name = o[:rpt_name] || get_expid_from_env()
    rpt_text = template.result(binding)
    fwrite('rpt_'+rpt_name+'.txt' , rpt_text )
    fwrite 'rpt_'+rpt_name+'.html' , apply_formatting(get_html_page(RedCloth.new(rpt_text).to_html))
  end
  
  #Make the index of reports
  def create_report_index()
    path = File.join(@name , "rpt")
    report_name, report_name_html = "index.txt" ,"index.html"
    files = [] ; Dir.entries(path).each do |fn|
      if !['.','..',report_name,report_name_html].include?(fn)
        files << File.new(File.join(path, fn))
      end
    end
    File.open(report_name , "w") do |f|
      f.puts "|_.Time|_.Type|_.Method|_.Remark|_.Options|"
      files.sort_by{|e|e.mtime}.reverse.map do |e|
        a = e.name.split("@").map{|e2|(e2.size > 0)? e2 : "None"}
        f.puts "|\"#{e.mtime}\":#{get_log_filepath(e.name)}|#{a[1]}|#{a[2]}|#{a[3]}|\"#{a[4]}\":#{get_rpt_filepath(e.name)}|"
      end
    end
    print_report( report_name , :path=>path )
  end
  
  def apply_formatting(text)
    text.gsub("<table>", "<table class='sortable'>")
  end

  def print_report( file_name , o = {})
    o[:format] ||= 'html'
    o[:path] ||= '.'
    File.open(File.join(o[:path] , File.basename(file_name,'.txt') + ".#{o[:format]}") ,'w') do |f|
      case o[:format]
      when 'html'
        f.puts(apply_formatting(get_html_page( RedCloth.new( prepare_html( IO.read(file_name) ) ).to_html)))
      when 'tex'
        template = ERB.new IO.read(o[:template] || to_path('template_latex.rhtml'))
        title = "Project Proposal"
        content = prepare_latex( IO.read(file_name) )
        f.puts template.result(binding)
      end
    end
  end
end

module FileHelper
  def fdump( dump_name , var )
    File.open( to_path(dump_name) , 'w') {|f| Marshal.dump(var , f) } ; var
  end
  
  def fload( dump_name )
    File.open( to_path(dump_name) , 'r') {|f| return Marshal.load(f) }
  end

  #check existence & size of file
  def fcheck(file_name , o = {})
    fullpath = (file_name[0..0]=='/')? file_name : to_path(file_name , o[:path])
    if !File.exists?(fullpath)
      return false
    else
      file_content = IO.read(fullpath)
      format_check = case file_name
                     when /\.res$/ : (file_content =~ /^[0-9]+ \S+ \S+ \S+ \S+/) != nil
                     when /\.eval$/ : (file_content =~ /^\S+\s+\S+\s+\S+$/) != nil
                     else
                       true
                     end
      #puts "name #{file_name} / content #{file_content}"
      if !format_check
        puts "Invalid format #{fullpath}"
        false
      else
        File.size(fullpath)
      end
    end
  end
  
  #write string rep. of the var
  def fwrite(file_name , var , o = {} , &filter)
    fullpath = to_path(file_name , o[:path])
    mode = o[:mode] || 'w'
    if o[:protect] && File.exist?(fullpath)
      return nil
    end
    var = var.split("\n").find_all{|e| if filter.call(e) then true else err("[fwrite] following was filtered : #{e}") ; false end }.join("\n") if block_given?
    File.open( fullpath , mode){|file| file.puts var}
    var
  end
  
  def fread(file_name , o = {})
    IO.read(to_path(file_name , o[:path]))
  end
  
  def fbkup(file_name , o = {})
    `cp #{to_path(file_name)} #{to_path(file_name)}.bak`
  end

  #read file line by line delimiter-separated
  def dsvread(file_name , o = {})
    fullpath = to_path(file_name , o[:path])
    IO.read( fullpath ).split("\n").map{|e|e.split(o[:sep_col] || " ")}
  end
  
  #write file line by line delimiter-separated
  # - input : [[r1c1, r1c2, ...], [r2c1, r2c2, ]]
  def dsvwrite(file_name, var, o = {})
    fwrite(file_name, var.map{|e|e.map{|e2|o[:enclose]? enclose(e2) : e2}.join(o[:sep_col] || " ")}.join("\n"), o)
  end
end