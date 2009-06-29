$ilab_root = '/work1/jykim/dev/rails/lifidea'
$indri_path = ENV['INDRI']
load 'ilab.rb'
$i = ILab.new('tblog')
$i.config_path( :work_path=>$exp_root+'/trecblog' ,:index_path=>'/work2/INDEXES/trecblog/index_permalinks_allwords' )

$method = 'qldm' if !defined?($method)

def ILabLoader.build(i)
  case $method
  when 'test'
    i.add_result_set('06.topics.851-900' , 'ql' ){|l|l[0] =~ /85[1-3]/}
    #i.add_query_set('06.topics.851-900' , 'dm'    , /\<title\> (.*)/ , :offset=>851  , :template=>dm_template )
  when 'qldm'
    i.add_query_set('06.topics.851-900' , 'ql' , /\<title\> (.*)/ , :offset=>851 )
    i.add_query_set('06.topics.851-900' , 'dm'    , /\<title\> (.*)/ , :offset=>851  , :template=>:dm )
    i.add_query_set('06.topics.851-900' , 'phrase_ql' , /\<title\> (.*)/ , :offset=>851  , :template=>'template_phrase.rhtml' )
    #i.add_query_set('06.topics.851-900' , 'phrase' , /\<title\> (.*)/ , :offset=>851  , :template=>'template_phrase_only.rhtml' )
  end
  i.add_relevant_set('qrels.blog06')
  i.fetch_data
  #result = i.rs['ql'].docs.map{|d| [d.qid , d.relevance > 0]}
  #result.group_by{|e|e[0]}.map{|k,v|[k , v.map{|e|e[1]}.avg_prec]}.sort_by{|e|e[0]}.each{|e|puts e.to_tbl }
  i.calc_length_stat
end

$i = ILabLoader.load($i)

if !$exp
  if $method =~ /^aw/
    $exp = 'allwords'
  else
    # $exp = 'query'
    $exp = 'length'
  end
end

eval IO.read(to_path('exp_'+$exp+'.rb'))
