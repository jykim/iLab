DEFAULT_ENGINE_TYPE = :indri
load 'ilab.rb'
#Set PATH
$exp_root = ENV['IH']
$indri_path = ENV['INDRI']
$trec_eval_path = ENV['WK']+'/app/trec_eval'

#Set Arguments
$o = {} if !defined?($o)
$i = ILab.new($col , get_opt_ilab($o)) 

#Set Global Vars
$t_start = Time.now
$ptn_qry_title = /\<title\> (.*)/
$ptn_qry_desc = /Description:\s?\n(.*?)^\<narr/m
$ptn_qry_narr = /Narration:\n(.*?)^\<narr/m

#Choose Collection
case $col
when 'ttb'
  $index_path = if $method =~ /ns/
                 '/work2/INDEXES/gov2_indri_2.5/gov2.p'  
               else
                 '/work2/INDEXES/gov2'
               end
  $i.config_path( :work_path=>$exp_root+'/ttb' ,:index_path=>$index_path )
  $file_topic = 'topics.701-850'
  $file_qrel = 'qrels.701-850'
  $offset = 701
when 'w10g'
  $index_path = $exp_root+'/w10g/index'
  $i.config_path( :work_path=> $exp_root+'/w10g' ,:index_path=> $index_path )
  $file_topic = 'topics.451-500'
  $file_qrel = 'qrels.trec9.main_web'
  $offset = 451
end

#Choose Retrieval Method
def ILabLoader.build(ilab)
  case $method
  when 'dir'
    ilab.crt_add_query_set('ql_d500_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:dirichlet,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_d1500_desc' , $ptn_qry_desc )
    ilab.crt_add_query_set('ql_d3000_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:dirichlet,mu:3000,operator:term' )
    ilab.crt_add_query_set('ql_d4500_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:dirichlet,mu:4500,operator:term' )

    ilab.crt_add_query_set('ql_d500' , :smoothing=>'method:dirichlet,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_d1500' )
    ilab.crt_add_query_set('ql_d3000' , :smoothing=>'method:dirichlet,mu:3000,operator:term' )
    ilab.crt_add_query_set('ql_d4500' , :smoothing=>'method:dirichlet,mu:4500,operator:term' )
    ilab.add_relevant_set($file_qrel)

  when 'jm'
    ilab.crt_add_query_set('ql_j0001' , :smoothing=>'method:jm,lambda:0.001,operator:term' )
    ilab.crt_add_query_set('ql_j03' , :smoothing=>'method:jm,lambda:0.3,operator:term' )
    ilab.crt_add_query_set('ql_j06' , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    ilab.crt_add_query_set('ql_j09' , :smoothing=>'method:jm,lambda:0.9,operator:term' )
    ilab.add_relevant_set($file_qrel)
    
  when 'qldm'
    ilab.crt_add_query_set('ql' )
    ilab.crt_add_query_set('dm'  , :template=>:dm )
    ilab.add_relevant_set($file_qrel)
  end#case
end

begin
  $i = ILabLoader.load($i)
rescue DataError
  puts 'Data inconsistency found while loading..'
  exit
end

if $o[:query_wise]
  #Length Stat
  $i.calc_length_stat

  #Restrict Relevant Set
  if $o[:lrange]
    $i.rl.docs.each{|e| e.relevance = 0 if !($o[:lrange] === e.size) }
  end

  #Perform. Stat
  $i.fetch_data if $i.rl

  #Stat (e.g. MAP)
  $i.calc_stat
end

#Run Experiment & Generate Report
$r = {}
eval IO.read(to_path('exp_'+$exp+'.rb'))
$i.create_report_index

info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
