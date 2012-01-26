load 'app/ilab.rb'
require 'nokogiri'

def parse_doc(filename)
  nk = Nokogiri::HTML(IO.read(filename))
  nk.xpath("//div[@id='vt-header']").map{|e|e.parent = nk.at_css "html"}
  begin
    text = nk.xpath("//div[@id='toadjaw-article']").map{|e|e.text()}.join("\n")
    title = nk.xpath("//h1[@id='vt-title']").first.text()
    url = nk.xpath("//div/a[text()='Original']").first['href']    
  rescue Exception => e
  end
  {:title=>(title || ""), :text=>(text || ""), :url=>(url || "")}
end

def index_doc(id, did, doc_hash)
  IR::Document.new(id, did, doc_hash.map_hash{|k,v|[k, LanguageModel.new(v)]})
end


def index_path(path)
  docs = {}
  Dir.entries(path).each_with_index do |fn,i| 
    next if ['.','..'].include?(fn)
    #puts fn
    docs[File.basename(fn, ".html")] = index_doc(i, File.basename(fn, ".html"), parse_doc(File.join(path,fn)))
  end
  docs
end

def calc_overlap(qwords, dlm, o = {})
  scores = qwords.map do |q|
    dlm[q] ? 1 : 0
  end
  scores.sum / qwords.size.to_f
end

def parse_query(query)
  query.split(/\s+/).map{|e|e.stem}
end

def process_input(file, ofile = nil)
  File.open( file ) do |f|
    File.open( ofile || file+'.out', 'w' ) do |of|
      while line = f.gets
        begin
          e = line.split("\t")
          #qid, query, tid, url_hash, tweet = e[0], e[1], e[3], e[7], e[12]
          qid, query, tid, url_hash, tweet = e[0], e[1], e[2], e[6], e[9]
          outrow = [qid, tid, url_hash]
          doc = $docs[url_hash]
          next if !doc
          qwords, twords = parse_query(query), parse_query(tweet)
          outrow.concat doc.flm.map{|k,v| calc_overlap(qwords,v.f).r3 }
          outrow.concat doc.flm.map{|k,v| calc_overlap(twords,v.f).r3 }
          of.puts outrow.join("\t")
        rescue Exception => e
          puts "Error in [#{line}]",e
        end
        #sleep(1)
      end
    end
  end
end

