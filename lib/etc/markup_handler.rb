#require 'application_framework'
#require 'latex_render.rb'
#require 'schedule_handler.rb'
#require 'CGI'

module MarkupHandler
  #include  LatexRenderHelper
  
  SEP_PAGES = /(?=(?:\A|\n)\{\{.*\}\})/
  #SEP_PAGES = /^---/
  SEP_SENTENCES = /[?.!] |\n/
  
  LOC_TITLE = -1
  LOC_TAG = -2
  LOC_CONTENT = -3

  CRTR_WEB = 'W'
  CRTR_ORGANIZER = 'O'

  #??? Decide which to use
  SEP_TAG = /\s*[,;]\s*/
  PTN_TAG = /([^,;\s]+)/
  
  #Mark-up for metadata {{Title|(Tag)|(CrtTime)|(Options)}}
  PTN_METADATA = /(?:\A|\n)\{\{(.*?)(?:\|(.*?)|)(?:\|(.*?)|)(?:\|(.*?)|)\}\}\s/
  
  #Mark-up for Query
  PTN_QUERY = /([PRC])\{\{(.*?)\}\}/

  PTN_MENU = /[M]\{\{(.*?)\|(.*?)\}\}/
  
  #Mark-up for Math
  PTN_MATH = /\$(\S*?)\$/
  PTN_MATH_BLOCK = /^<math>(?:.*?)$(.*?)^<\/math>/m
  
  #Mark-up for Concept [[Concept.title]]
  PTN_CONCEPT = /\[\[(.*?)\]\]/

  #Mark-up for realtion btw. concepts [[Concept<>/</>/=Concept]]
  SEP_CONCEPT_RELATION = /<>|<|>|=/
  PTN_CONCEPT_RELATION = /([^<>=]+)(?:(<>|<|>|=)([^<>=]+))*/
  
  #Mark-up for comment blocks
  PTN_BLOCK = /^\{\{\{(.*?)^\}\}\}/m

  #Mark-up for Comments
  PTN_COMMENT = /([^:])(\/\/)(.*)$/
  PTN_COMMENT_MULTILINE = /(\/\*)(.*?)(\*\/)/m
  
  DEF_EXPORT_FILENAME = 'export.txt'
  
  LATEX_SERVER = "http://www.forkosh.dreamhost.com/mimetex.cgi?"
  #LATEX_SERVER = "http://httex.org/png/tex.py?tex="

  def strip_tags text
    text.gsub! PTN_BLOCK , ""
    text.gsub! PTN_COMMENT , "\\1"
    text.gsub! PTN_COMMENT_MULTILINE , ""
  end
  
  def prepare_latex(content , o = {})
    #,'{','}','\\'
    #content.gsub! /_(.*?)_/m ,"\\emph{\\1}"
    content.gsub! /'(.*?)'/m , "`\\1'"
    
    content.gsub! /\[([0-9]+?)\]/ ,"\\cite{\\1}"
    content.gsub! /^fn([0-9]+?)\. (.*)/ ,"\\bibitem{\\1} \\2"
    
    content.gsub! /^= ([^\n\r]*)( =)?/ ,"\\section{\\1}"
    content.gsub! /^== ([^\n\r]*)( ==)?/ ,"\\subsection{\\1}"
    content.gsub! /^=== ([^\n\r]*)( ===)?/ ,"\\subsubsection{\\1}"
    content.gsub! /^==== ([^\n\r]*)( ====)?/ ,"\\paragraph{\\1}"
    content.gsub! /^===== ([^\n\r]*)( =====)?/ ,"\\subparagraph{\\1}"
    
    content.gsub! /([^|])\n\|/ ,"\\1\n\\begin{tabular}{l|l}\n|"
    content.gsub! /\|\n([^|])/ ,"|\n\\end{tabular}\n"
    
    content.gsub! /!([\w_]\.[\w])!/ ,"\\includegraphics{\\1}"
    
    content.gsub! /^([^*]+?)\n(?= \*)/ ,"\\1\n\\begin{itemize}\n"
    1.upto 5 do |no| content.gsub! /^(\s{#{no}}\*.*)\n(?=[^*]+?(?:$|\Z))/ ,"\\1\n#{"\\end{itemize}\n"*no}" end
    
    content.gsub! /^\{\{\[/ , "\[" ; content.gsub! /\]\}\}/ , "\]"
    
    1.upto 5 do |no| content.gsub! /^(\s{#{no}}\*.*)\n(\s{#{no+1}}\*.*)$/ ,"\\1\n\\begin{itemize}\n\\2" end
    1.upto 5 do |no| content.gsub! /^(\s{#{no+1}}\*.*)\n(\s{#{no}}\*.*)$/ ,"\\1\  n\\end{itemize}\n\\2" end
    content.gsub! /^(\s+\*)/ ,"\\item"
    
    #content.gsub! /\|\n([^|])/ ,"|\n\\end{tabular}\n"    
    ['#','%','&','~'].each do |c| content.gsub! "#{c}" , "\\#{c}" end
    content
  end

  def get_math_img(str)
    return "" if ENV['RAILS_ENV'] != 'production'
    #"<img alt=\"#{str}\" src=\"#{LATEX_SERVER}#{CGI.escape str}\" style=\"VERTICAL-ALIGN:middle\">" 
    "<img src=\"#{LATEX_SERVER}#{CGI.escape str}\" style=\"VERTICAL-ALIGN:middle\">" 
  end

  # Pre-process page contents for HTML presentation
  def prepare_html(content , page_type = 'N')
    #header
    1.upto 5 do |no| content.gsub! /^(={#{no}}) (.*) (={#{no}})/ ,"\nh#{no+1}. \\2\n" end
    1.upto 5 do |no| content.gsub! /^(={#{no}}) (.*)/ ,"\nh#{no+1}. \\2\n" end

    #list
    1.upto 5 do |no| content.gsub! /^([ ]{#{no}})(\*) ?(.*)/   ,"#{'*'*no} \\3" end
    1.upto 5 do |no| content.gsub! /^([ ]{#{no}})(#) ?(.*)/   ,"#{'#'*no} \\3" end
    #content.gsub! /(\*) v (.*)/ , "\\1 -\\2-"
    
    #block
    content.gsub! /^\{\{\{/ , "<pre>" ; content.gsub! /^\}\}\}/ , "</pre>"
    content.gsub! /^\{\{\"/ , "<blockquote>" ; content.gsub! /^\"\}\}/ , "</blockquote>"
    content.gsub! /^\{\{\[/ , "<math>" ; content.gsub! /^\]\}\}/ , "</math>"
    
    #concept & property
    content.gsub! /\[\[(.*?):=(.*?)\]\]/ , '\1(\2)'
    #content.gsub! /\[\[(.*?)[<>=].*?\]\]/ , \"\\1\":#{APP_ROOT}/page/\\1" 
    content.gsub! /\[\[(.*?)\]\]/ , "\"\\1\":#{APP_ROOT}/entry/\\1" if defined?(APP_ROOT)

    #comment
    content.gsub! PTN_COMMENT , "\\1"
    content.gsub! PTN_COMMENT_MULTILINE , ""
    if defined? SystemConfig
      SystemConfig.site_info.each do |e|
        content.gsub! /(\s)#{e[1]}:/ , "\\1#{e[2]}"
      end
      content.gsub! SystemConfig.ptn_url_unnamed , "\\1\"\\2\":\\2"
      content.gsub! "%ROOT%" , APP_ROOT
    end
    
    #Process by page_type
    case page_type
    when 'N'
      math_list = content.scan( PTN_MATH ) ; math_list.each do |m|
        #content.gsub! "$#{m[0]}$" , latex_render(m[0])
        content.gsub! "$#{m[0]}$" , get_math_img(m[0])
      end
      math_block_list = content.scan( PTN_MATH_BLOCK ) ; math_block_list.each do |m|
        #content.gsub! "#{m[0]}" , latex_render(m[0])
        content.gsub! "#{m[0]}" , get_math_img(m[0])
      end
    when 'S'
      menu_list = content.scan( PTN_MENU ) ; menu_list.each do |m|
        menu_title = m[0] ; menu_target = m[1] ; menu_str = "M{{#{menu_title}|#{menu_target}}}"
        #$lgr.info "#{menu_title} / #{menu_target}"
        result = link_to_remote(menu_title , :url => { :action => 'menu' , :query => CGI.escape(menu_target) })
        content.gsub! menu_str , result
      end
    end
    #$lgr.info "[prepare_html] "+content
    query_list = content.scan( PTN_QUERY ) ; query_list.each do |q|
      query_type = q[0] ; query_content = q[1] ; query_str = "#{query_type}{{#{query_content}}}"
      case query_type
      when 'P'
        result = eval("find_page :display=>'|@title|@tags|@created_at|' ," + query_content )
        result = result.join("\n") if result.class == Array
        result = "|_.Title|_.Tag|_.CreatedAt|\n"+result if query_content.scan(/:display/).size == 0
        #$lgr.info "[prepare_html] Query : #{query_str} , #{result}"
        content.gsub! query_str , result
      end
    end
    #content.gsub! SystemConfig.ptn_url , "\"\\0\":\\0"
    #???content.gsub!(SystemConfig.ptn_site) "\"#{ApplicationController.SystemConfig(\\0)}\":\\0"
    content
  end
  
  def eval_erb_text(content , arg_binding = nil)
    template = ERB.new(content)
    template.result(arg_binding || binding)
  end
  
  #Inport Tagged Text from Given Path
  # - 
  def import_markup_text( file_content )
    count = 0
    if file_content.scan(PTN_LINE)[0] =~ /tattertools/
      file_content = convert_tatter_xml( file_content )
      return file_content
    end
    count += create_pages( :content => file_content )
    count
  end
  
  def export_markup_text( file_name )
    export_path = File.join(PATH_DATA , (file_name.blank? ? DEF_EXPORT_FILENAME : file_name ))
    $lgr.info "[export_markup_text] path = #{export_path}"
    File.open( export_path ,'w') do |file|
      Page.find(:all).each do |t|
        file.puts t.serialize
      end
    end
    export_path
  end
  
  # Process text to create pages
  # - out : no. of pages created
  def create_pages(page)
    skip_count = 0
    page[:content].split( SEP_PAGES ).each_with_index do |content,i|
      if content =~ PTN_METADATA
        page[:title] = $1;page[:tag] = $2
        page[:created_at] = str2time( $3 ) if !$3.blank?
        h = {};$4.split('|').each{|e| pair = e.split('=') ; h[pair[0].to_sym] = pair[1] }
        h[:public_flag] = false if !h[:public_flag] || h[:public_flag] != "true"
        h[:page_type] = 'N' if !h[:page_type]
        page.merge!(h)
        #$lgr.info page.inspect
        content.gsub! PTN_METADATA , ""
      end
      page[:content] = content
      extract_data Page.create!(page)
    end.length
  end

  #Process Concept/URL Information from Page Instance
  def extract_data( page )
    strip_tags page[:content]

    #extract_concepts( page[:title]   , page , LOC_TITLE ) if page[:title] && page[:title] !=~ PTN_EMPTY
    if page[:tag] && page[:tag] !=~ PTN_EMPTY
      page[:tag] = page[:tag].split(SEP_TAG).map{|e|"[["+e+"]]"}.join(";")
      extract_concepts( page[:tag]   , page , LOC_TAG )
    end

    extract_concepts( page[:title] , page , LOC_TITLE)
    extract_concepts( page[:content] , page )
    extract_resources( page[:content] , page )
  end
  
  def extract_resources( content , page)
    content.scan( SystemConfig.ptn_url ).each do |url_content|
      resource = Resource.create!( :content => url_content)
      ResourceOccurrence.create!( :page => page , :resource => resource , :location => LOC_CONTENT)
    end
    site_urls = content.scan( SystemConfig.ptn_site ).each do |url_content|
      url_content =~ /([^:]+):/;site_prefix = $1
      resource = Resource.create!( :site_prefix => site_prefix , :content => SystemConfig.site_url_conv(site_prefix , url_content))
      ResourceOccurrence.create!( :page => page , :resource => resource , :location => LOC_CONTENT)
      #TODO Duplication
    end
  end
  
  #Extract & Save concept & properites from given page
  def extract_concepts( content , page , location = LOC_CONTENT)
    #$lgr.info("Content : #{content} ")
    content.scan( PTN_CONCEPT ).each do |concept_title|
      if /(\w+):=(.*)/ =~ concept_title[0]
        Property.create!( :page => page , :name => $1 , :value => $2 )
        next
      end
      refs = PTN_CONCEPT_RELATION.match(concept_title[0])
      #$lgr.info refs.to_a.inspect
      data = [] #Concept instance for odd index, ConceptRelation instance for even index
      if refs.size % 2 != 0 then flash[:notice] = "Illegal concept definition! #{refs[0]}" end
        
      refs.to_a.each_with_index do |match_str , i|
        #$lgr.info("  [#{i}]=>[#{match_str}] / ")
        if match_str == nil || match_str.length == 0 then break end
        if i == 0 then next end
        if i % 2 == 1 #Concept
          data[i] = Concept.find_by_title( match_str )
          if data[i] == nil
            data[i] = Concept.create!( :title=>match_str )
          end
          #ConceptOccurrence will be handled by Organizer
          ConceptOccurrence.create!( :page => page , :concept => data[i] , :location => location)
          #Finalize ConceptRelation
          if i > 1
            data[i-1].other_concept = data[i]
            data[i-1].page = page
            data[i-1].save
            #$lgr.info data[i-1].inspect
          end
        elsif i % 2 == 0 #ConceptRelation
          data[i] = ConceptRelation.new
          data[i].concept = data[i-1]
          data[i].kind = match_str
        end
      end # end of block
    end #end of block
  end
  
private
  def convert_tatter_xml( file_content )
    require 'rexml/document'
    require 'clothred'
    xml = REXML::Document.new( file_content ) ; s = ""
    xml.elements.each("//post") do |p|
      t = Page.new
      t.title = p.elements["title"].get_text.to_s
      t.permlink = p.attributes["slogan"]
      t.page_type = "N"
      t.public_flag = p.elements["visibility"].get_text.to_s != 'private'
      content_html = ClothRed.new p.elements["content"].get_text.to_s ; t.content = content_html.to_textile
      t.created_at = Time.at p.elements["created"].get_text.to_s.to_i if p.elements["created"]
      t.updated_at = Time.at p.elements["modified"].get_text.to_s.to_i if p.elements["modified"]
      t.published_at = Time.at p.elements["published"].get_text.to_s.to_i if p.elements["published"]
      $lgr.info "Title : " + p.elements["title"].get_text.to_s
      $lgr.info "Creation Time : " + p.elements["created"].get_text.to_s
      s += t.serialize
    end
    s
  end
end
