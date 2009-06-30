require 'net/http'
require 'rexml/document'
include REXML
class YahooInterface
  attr_reader :appid, :pg
  def initialize( o = {})
    @appid = o[:appid] || "f9yVorbV34HgP6nBkjCkvnoENrNfwUM0R3KpdQG.jaWhhOJv984SstQRXMo-"
  end

  def to_fname(str)
    str.downcase.scan(/[a-z]/).join("")
  end
    
  
  def fetch_page(query , o= {})
    file_path = File.join(o[:out_path], "meta_#{to_fname(query)}_#{o[:type]}_#{o[:start]}.xml")
    if File.exist?(file_path)
      content = IO.read(file_path)
    else
      File.open(file_path, 'w') do |f| 
        content = Net::HTTP.get(URI.parse("http://boss.yahooapis.com/ysearch/web/v1/=#{query}?count=50&start=#{o[:start]}&type=#{o[:type]}&format=xml&lang=en&region=us&appid=#{@appid}"))
        f.puts content
      end
    end
    return Document.new(content)
  end
  
  def search(query , o = {})
    o[:limit] ||= 50
    o[:out_path] ||= "."
    o[:out_prefix] ||= to_fname(query)
    0.step(o[:limit], 50) do |start|
      @pg = fetch_page(query , o.merge(:start=>start))
      i = 0
      @pg.elements.each("*/*/result") do |e|
        puts "Title : "+e.elements["title"].text
        ext = to_ext(o[:type])
        out_filename = "#{o[:out_path]}/#{o[:type]}/#{o[:out_prefix]}_#{start+i}.#{ext}" ; i+=1
        `mkdir -p #{File.dirname(out_filename)}` if !File.exist?(File.dirname(out_filename))
        run_wget(out_filename, e.elements["url"].text)
        next if !File.exists?( out_filename ) || File.stat(out_filename).size == 0
        if !File.exists?( "#{out_filename}.txt" )
          next if !conv_text(out_filename , ext)
        end
        opt = {:title=>e.elements["title"].text, :abstract=>e.elements["abstract"].text, 
          :url=>e.elements["url"].text, :date=>e.elements["date"].text, :text=>IO.read("#{out_filename}.txt") }
        create_doc(o[:out_path]+"/#{o[:type]}_doc", File.basename(out_filename) , opt)
      end
      next_page = XPath.first(@pg , "//nextpage")
      if next_page
        puts "-- next page! #{next_page}--"
      else
        break
      end#if
    end#doc
  end#page
end

def run_wget(out_filepath, url, o={})
  if o[:redo] == true || !File.exists?( out_filepath )
    cmd = "wget -t 2 -T 30 -O #{out_filepath} #{url}"
    sleep 0.01
    #cmd = "wget -P #{out_path} -t 2 -T 30 -O #{out_filename} #{url}"
    puts cmd
    `#{cmd}`
  end
  if o[:read] == true
    IO.read(out_filepath)
  end
end