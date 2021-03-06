load 'lib/object/document_set_helper.rb'
load 'lib/object/document.rb'
load 'lib/object/occurrence.rb'
load 'lib/object/term.rb'
load 'lib/object/term_relation.rb'

Measure = Struct.new(:title , :calc_str)

#DocumentSet for LBKD
#
# = Background
# * Document Set 
# * Each element is assumed to have a unique ID
class DocumentSet
  include ILabHelper
  attr_accessor :name , :docs , :dh , :dhq , :engine
  def initialize( name , o = {})
    @name = name
    @o = o
    @engine = o[:engine] || $engine
    clear
  end

  def to_s
    "DocSet #@name (#{@docs.size} docs)"
  end

  def inspect
    to_s
  end

  def clear
    @docs = []
    @dh = {}
    @dhq = {}
  end
  
  #Get length distribution of all docs
  def ldist(o={})
    #if defined? @ldist then return @ldist end
    @ldist = @docs.map{|d|d.size}.to_dist(o[:bucket_size] || 100)
  end
  
  #Add document
  def add_doc( doc )
    @docs << doc
    @dh[doc.did] = doc
    @dhq[doc.qid] = [] if !@dhq[doc.qid]
    @dhq[doc.qid] << doc
  end
  
  #Import document list 
  def import_docs( docs )
    @docs = docs
  end
  
  def remove_docs_if( &filter )
    size_b = @docs.size
    @docs = @docs.find_all{|d| !filter.call(d) }
    puts "#{size_b - @docs.size} docs removed!"
  end
  
  #Export doc list to html
  def export_docs( o = {} , &filter )
    return "" if @docs.size == 0
    #info "[export_docs] === START === "
    doc_list = "|Rank|Title|"
    doc_list += "Score|" if $exp == 'adhoc'
    doc_list += "Qid|Did|" if $exp == 'qrel'
    doc_list += "Query|Relevance|Length|Type|Remark|" if o[:verbose]
    doc_list += "HRS|Length|DiffT|URL|RT|QTol|" if $col == 'twir'
    doc_list += "\n"
    @docs.find_all{|d| (block_given?)? filter.call(d) : true }.each_with_index do |d,i|
      d.fetch_info(fetch_doc_data(d.did), @engine.title_field, o) if !d.dno
      #info "[export_docs] #{d.title} (#{i})"
      doc_file_name = ["doc" , File.basename(d.did)].join('_') + '.' + 'html' 
      if $exp != 'adhoc'
        doc_color = if d.relevance >  1 : "background:#444444" 
                    elsif d.relevance == 1 : "background:#888888" 
                    elsif d.relevance == 0 : "background:#ffffff"
                    elsif d.relevance == -1 : "background:#cccccc"
                    else "background:#aaaaaa"
                    end
      end
      doc_info = [ (defined?(d.rank))? d.rank : 'N/A' ,"\"#{d.title.gsub(/\W+/," ").strip}\":../../doc/#{doc_file_name}" ]
      #puts Time.parse($qtime_filters[d.qid-1].scan(/\d+/)[0]), Time.parse(d.text.find_tag("qtime")[0])
      difft = (Time.parse($qtime_filters[d.qid-1].scan(/\d+/)[0]) - Time.parse(d.text.find_tag("qtime")[0])) / 86400
      query_a, doc_a = $i.qsa[0].qh[d.qid].text.scan(/\w+/), d.text.scan(/\w+/)
      #p query_a, doc_a
      qtol = query_a.map{|q|(doc_a.include?(q))? 1 : 0 }.sum / query_a.size.to_f
      doc_info << [ d.relevance, doc_a.size, difft.r3, d.text.scan("http").size, d.text.scan("RT").size, qtol.r3 ] if $col == 'twir'
      doc_info << [ d.qid , d.relevance, d.size , d.type , d.remark  ] if o[:verbose]
      doc_info << [ d.qid , d.did  ] if $exp == 'qrel'
      doc_info << [ d.score ] if $exp == 'adhoc'
      doc_info << [ "\"Link\":"+d.text.find_tag("URL").first.strip ] if d.text.find_tag("URL").size > 0
      doc_list += (doc_info.to_tbl(:style=>doc_color)+"\n")
      fwrite doc_file_name , $engine.annotate_text_with_query(clean_content(d), o[:query]) if !fcheck(doc_file_name)
    end
    doc_list
  end
  
  def fetch_doc_data( did )
    dno = @engine.to_dno(did)
    info "[fetch_doc_data] no document found for #@name : #{did}" if dno < 1
    @engine.get_index_info( 'dd', "#{dno}")
  end

  def clean_content(d)
    d.text.gsub!(/\A\n+/ , "")
    #d.text.gsub!(/(http:\/\/\s+?)/, )
    case d.type
    when /pdf/i
      d.text.gsub(/\n/ , "<br>")
    else 
      if d.text.scan(/\<\?xml/).size == 0
        "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?><doc>#{d.text}</doc>"
      else
        d.text
      end
    end
  end
  
  #Create new document set by applying filter to existing one
  def self.create_by_filter(set_name , old_set , &filter)
    ds = old_set.dup
    ds.clear ; ds.name = set_name
    old_set.docs.find_all{|d| (block_given?)? filter.call(d) : true }.each{|d| ds.add_doc( d.dup ) }
    info "[create_by_filter] #{old_set.docs.size} -> #{ds.docs.size}"
    ds
  end

private

end
