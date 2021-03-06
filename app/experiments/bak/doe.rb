$ilab_root = '/work1/jykim/dev/rails/lifidea'
$indri_path = ENV['INDRI']
require 'rubygems'
load 'ilab.rb'
i = ILab.new('doe') 
i.config_path( :work_path=> $exp_root+'/doe' ,:index_path=> $exp_root+'/doe/doe_index' )
$file_topic = 'topics.1-100'
$file_qrel = 'qrel.1-100'
# $file_qrel_aw = 'qrels.701-850.allwords'

$method = ARGV[0] if !defined?($method)
$exp = ARGV[1] if !defined?($exp)

def ILabLoader.build(i)
  case $method
  when 'test'
    i.add_result_set('ql.res' , 'ql' ){|l|l[0] =~ /70[1-3]/}
    i.add_result_set('dm.res' , 'dm' ){|l|l[0] =~ /70[1-3]/}
    i.add_relevant_set($file_qrel) # {|l|l[0] =~ /70[1-3]/}
  when 'allwords_partial'
    h = {"787"=>893, "808"=>263, "831"=>631, "798"=>715, "709"=>152, "765"=>45, "843"=>539, "810"=>265, "755"=>83, "744"=>185, "766"=>391, "733"=>108, "811"=>588, "745"=>46, "812"=>638, "724"=>417, "801"=>59, "746"=>49, "845"=>389, "813"=>902, "835"=>42, "802"=>499, "769"=>148, "736"=>280, "791"=>3, "759"=>191, "814"=>606, "726"=>454, "737"=>406, "716"=>3, "771"=>129, "738"=>355, "793"=>68, "705"=>512, "760"=>518, "783"=>770, "838"=>211, "750"=>749, "805"=>588, "827"=>107, "706"=>726, "784"=>31, "839"=>164, "751"=>102, "773"=>81, "795"=>1, "707"=>768, "817"=>568, "730"=>181, "785"=>161, "807"=>692, "719"=>470, "796"=>53, "708"=>153, "818"=>273, "786"=>978, "841"=>619, "742"=>413, "731"=>606}
    i.add_result_set('ql.res' , 'ql' ){|l| h[l[0]] }
    i.add_result_set('dm.res' , 'dm' ){|l| h[l[0]] }
    i.add_result_set($file_qrel , 'rel_o' ){|l| h[l[0]] && l[3].to_i > 0 }
    i.add_relevant_set($file_qrel_aw){|l| h[l[0]] }
  when 'aw2'
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql.res' , 'ql' ){|l| !h[l[0]] }
    i.add_result_set('dm.res' , 'dm' ){|l| !h[l[0]] }
    i.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    i.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'aw2jm'
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql_j00.res' , 'ql_j00' ){|l| !h[l[0]] }
    i.add_result_set('ql_j01.res' , 'ql_j01' ){|l| !h[l[0]] }
    i.add_result_set('ql_j03.res' , 'ql_j03' ){|l| !h[l[0]] }
    i.add_result_set('ql_j06.res' , 'ql_j06' ){|l| !h[l[0]] }
    i.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    i.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'aw2dir'
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql_d500.res' , 'ql_d500' ){|l| !h[l[0]] }
    i.add_result_set('ql_d1500.res' , 'ql_d1500' ){|l| !h[l[0]] }
    i.add_result_set('ql_d3000.res' , 'ql_d3000' ){|l| !h[l[0]] }
    i.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    i.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'aw'
    #$query_allwords = $work_path+'/template_query_allwords.rhtml'
    #i.add_query_set($file_topic  , 'allwords' , /\<title\> (.*)/ , :offset=>701 , :template=>$query_allwords ) # {|e|e =~ /^ca/}
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql.res' , 'ql' ){|l| !h[l[0]] }
    i.add_result_set('dm.res' , 'dm' ){|l| !h[l[0]] }
    i.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }
    i.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'awjm'
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql_j00.res' , 'ql_j00' ){|l| !h[l[0]] }
    i.add_result_set('ql_j01.res' , 'ql_j01' ){|l| !h[l[0]] }
    i.add_result_set('ql_j03.res' , 'ql_j03' ){|l| !h[l[0]] }
    i.add_result_set('ql_j06.res' , 'ql_j06' ){|l| !h[l[0]] }
    i.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
    i.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }
  when 'awdir'
    h = {"832"=>false , "749"=>false}
    i.add_result_set('ql_d500.res' , 'ql_d500' ){|l| !h[l[0]] }
    i.add_result_set('ql_d1500.res' , 'ql_d1500' ){|l| !h[l[0]] }
    i.add_result_set('ql_d3000.res' , 'ql_d3000' ){|l| !h[l[0]] }
    i.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
    i.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }
  when 'dir'
    i.add_query_set($file_topic  , 'ql_d500' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:dirichlet,mu:500,operator:term' )
    i.add_query_set($file_topic  , 'ql_d1500' , /\<title\> (.*)/ , :offset=>701 )
    i.add_query_set($file_topic  , 'ql_d3000' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:dirichlet,mu:3000,operator:term' )
    i.add_relevant_set($file_qrel)
  when 'jm'
    i.add_query_set($file_topic  , 'ql_j00' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:jm,lambda:0,operator:term' )
    i.add_query_set($file_topic  , 'ql_j01' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:jm,lambda:0.1,operator:term' )
    i.add_query_set($file_topic  , 'ql_j03' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:jm,lambda:0.3,operator:term' )
    i.add_query_set($file_topic  , 'ql_j06' , /\<title\> (.*)/ , :offset=>701 , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    i.add_relevant_set($file_qrel)
  when 'two'

  when 'qldm_ns'
    i.add_query_set($file_topic  , 'ql_o' , /\<title\> (.*)/ , :offset=>701 )
    i.add_query_set($file_topic  , 'dm_o' , /\<title\> (.*)/ , :offset=>701  , :template=>:dm )
    i.add_query_set($file_topic  , 'ql_ns' , /\<title\> (.*)/ , :offset=>701 )
    i.add_query_set($file_topic  , 'dm_ns' , /\<title\> (.*)/ , :offset=>701  , :template=>:dm )
    #i.add_query_set($file_topic  , 'narr' , /\<narr\> Narrative:(.*?)\<\/top\>/m , :offset=>701 )
    #i.add_query_set($file_topic  , 'desc' , /\<desc\> Description:(.*?)\<narr\>/m , :offset=>701 )
    i.add_relevant_set($file_qrel)
    #i.run_query_set('topic')
  when 'qldm'
    i.add_query_set($file_topic  , 'ql' , /\<title\> (.*)/ , :offset=>1 )
    i.add_query_set($file_topic  , 'dm' , /\<title\> (.*)/ , :offset=>1  , :template=>:dm )
    #i.add_query_set($file_topic  , 'narr' , /\<narr\> Narrative:(.*?)\<\/top\>/m , :offset=>701 )
    #i.add_query_set($file_topic  , 'desc' , /\<desc\> Description:(.*?)\<narr\>/m , :offset=>701 )

    i.add_relevant_set($file_qrel)
  else
    puts 'Specify Query!'
  end
  #i.run_query_set('topic')  
  #Perform. Stat
  i.fetch_data if i.rl
  #Length Stat
  i.calc_length_stat
end

i = ILabLoader.load(i)


if !$exp
  if $method =~ /^aw/
    $exp = 'allwords'
  else
    # $exp = 'query'
    $exp = 'length'
  end
end

eval IO.read('exp_'+$exp+'.rb')
