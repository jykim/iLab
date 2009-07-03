DEFAULT_ENGINE_TYPE = :indri
#$ilab_root = '/work1/jykim/dev/rails/lifidea'
load 'ilab.rb'
#Set PATH
$exp_root = ENV['IH']
$indri_path = ENV['INDRI']
$r_path = ENV['R_PROJECT']
$trec_eval_path = ENV['WK']+'/app/trec_eval'

#Set Arguments
get_env_from_expid(ARGV[0]) if ARGV.size > 0
$o = {} if !defined?($o)
$qry_type = $o[:qry_type] || 'title'
$i = ILab.new($col , get_opt_ilab($o)) 

#Set Global Vars
$t_start = Time.now
$ptn_qry_title = /\<title\> (.*)/
$ptn_qry_desc = /Description:\s?\n(.*?)^\<narr/m
$ptn_qry_narr = /Narration:\n(.*?)^\<narr/m

def get_ptn_query(qry_type)
  case qry_type
  when 'title' : $ptn_qry_title
  when 'desc' : $ptn_qry_desc
  when 'narr' : $ptn_qry_narr
  end
end

#Choose Collection
case $col
when 'ttb'
  index_path = if $method =~ /ns/
                 '/work2/INDEXES/gov2_indri_2.5/gov2.p'  
               else
                 '/work2/INDEXES/gov2'
               end
  $i.config_path( :work_path=>$exp_root+'/ttb' ,:index_path=>index_path )
  $file_topic = 'topics.701-850'
  $file_qrel = 'qrels.701-850'
  $file_qrel_aw = 'qrels.701-850.allwords'
  $offset , $count = 701 , 150
  $param_opt = 'method:opt,lengths:0|100|200|300|400|500|800|1100|2200|127300,lambdas:0.95|0.9375|0.882352941|0.8|0.756140351|0.733333333|0.685507246|0.593589744|0.322072072|0.136645963'
  $param_dir = 'method:opt,lengths:0|100|200|300|400|500|800|1100|2200|127300,lambdas:1|0.9375|0.882352941|0.833333333|0.789473684|0.75|0.652173913|0.576923077|0.405405405|0.011645963'
when 'ttbs'
  index_path = '/work2/INDEXES/gov2'
  $i.config_path( :work_path=>$exp_root+'/ttbs' ,:index_path=>index_path )
  $file_topic = 'topics.701-710'
  $file_qrel = 'qrels.701-850'
  $offset = 701
  $param_opt = 'method:opt,lengths:0|100|200|300|400|500|800|1100|2200|127300,lambdas:0.9375|0.8875|0.81985294117647|0.808333333333333|0.789473684210526|0.7625|0.677173913043478|0.639423076923077|0.430405405405405|0.0116459627329193'

when 'ttbm'
  index_path = '/work2/INDEXES/gov2'
  $i.config_path( :work_path=>$exp_root+'/ttbm' ,:index_path=>index_path )
  $file_topic = 'topics.701-800'
  $file_qrel = 'qrels.701-850'
  $offset = 701
  # $param_opt = 'method:opt,lengths:0|100|200|300|400|500|800|1100|2200|127300,lambdas:0.925|0.8875|0.80735294117647|0.808333333333333|0.789473684210526|0.775|0.677173913043478|0.651923076923077|0.455405405405405|0.0866459627329193'
  $param_opt = 'method:opt,lengths:0|100|200|300|400|500|800|1100|2200|127300,lambdas:0.9375|0.8875|0.81985294117647|0.808333333333333|0.789473684210526|0.7625|0.677173913043478|0.639423076923077|0.430405405405405|0.0116459627329193'
when 'trecblog'
  $i.config_path( :work_path=>$exp_root+'/trecblog' ,:index_path=>'/work2/INDEXES/trecblog/index_permalinks_allwords' )
  $file_topic = '06.topics.851-900'
  $file_qrel = 'qrels.blog06'
  $offset = 851
when 'trec3'
  $i[:bucket_size] = 10
  $i.config_path( :work_path=>$exp_root+'/trec3' ,:index_path=>$exp_root+'/trec3/index_new' )
  $file_topic = 'topics.151-200'
  $file_qrel = 'qrels.151-200'
  $offset , $count = 151 , 50
  $range_test = (186..200)
  $param_opt = "method:opt,lengths:0|90|130|200|460|423560,lambdas:1|0.960062893|0.928578732|0.865686275|0.698639456|0.128528914"
  $param_dir = "method:opt,lengths:0|90|130|200|460|423560,lambdas:1|0.943396226|0.920245399|0.882352941|0.765306122|0.003528914"
  $ptn_qry_title = /\<title\> Topic: (.*?)\<desc\>/m
  $ptn_qry_desc = /\<desc\> Description:(.*?)\<narr/m
  $ptn_qry_narr = /\<narr\>  Narrative : (.*?)/m
when 'w10g'
  $i[:bucket_size] = 25
  $i.config_path( :work_path=> $exp_root+'/w10g' ,:index_path=> $exp_root+'/w10g/index' )
  $file_topic = 'topics.451-500'
  # $file_topic = 'topics.451-500.short'
  #$param_opt = "method:opt,lengths:0|75|175|300|650|514425,lambdas:0.983333333|0.952380952|0.895522388|0.85|0.697674419|0.102907399"
  $param_opt = "method:opt,lengths:0|75|175|300|650|514425,lambdas:1|0.952380952|0.945522388|0.883333333|0.647674419|0.102907399"
  $param_dir = "method:opt,lengths:0|75|175|300|650|514425,lambdas:1|0.952380952|0.895522388|0.833333333|0.697674419|0.002907399"
  $file_qrel = 'qrels.trec9.main_web'
  $offset , $count = 451 , 50
  $range_test = (486..500)
  # $file_qrel_aw = 'qrels.701-850.allwords'
end

info "[run.rb] #{$o.inspect}"
if $o[:env] == 'cval'
  $param_opt = ARGV[1] if ARGV[1]
  $range_test = get_cval_range($offset, $count, $o[:cval_no], $o[:cval_id])
  $range_tune = get_cval_range($offset, $count, $o[:cval_no], (($o[:cval_no]==$o[:cval_id]+1)? 0 : $o[:cval_id]+1))
  info("Cross Validation #{$o[:cval_id]} with range #{$range_test}")
  info("param_opt = #{$param_opt}") if $param_opt
end

#['length'].each{|e| $i.engine.run_make_prior(e) }

#Choose Retrieval Method
def ILabLoader.build(ilab)
  case $method
  when 'test'
    ilab.add_result_set('ql.res' , 'ql' ){|l|l[0] =~ /70[1-3]/}
    ilab.add_result_set('dm.res' , 'dm' ){|l|l[0] =~ /70[1-3]/}
    #ilab.crt_add_query_set('test_title' , :remote_query=>true )
    #ilab.crt_add_query_set('test_desc' , :topic_pattern=>$ptn_qry_desc , :remote_query=>true )
    #ResultDocumentSet.create_by_fusion('test_fusion' , ilab.rsa , :mode=>'CombMNZ')
    #ilab.add_result_set('test_fusion.res' , 'test_fusion')
    #ilab.crt_add_query_set('opt_test' , :smoothing=>'method:opt,lengths:0|100|1000,lambdas:0.4|0.4|0.4' )
    ilab.add_relevant_set($file_qrel)
    
  when 'allwords_partial'
    h = {"787"=>893, "808"=>263, "831"=>631, "798"=>715, "709"=>152, "765"=>45, "843"=>539, "810"=>265, "755"=>83, "744"=>185, "766"=>391, "733"=>108, "811"=>588, "745"=>46, "812"=>638, "724"=>417, "801"=>59, "746"=>49, "845"=>389, "813"=>902, "835"=>42, "802"=>499, "769"=>148, "736"=>280, "791"=>3, "759"=>191, "814"=>606, "726"=>454, "737"=>406, "716"=>3, "771"=>129, "738"=>355, "793"=>68, "705"=>512, "760"=>518, "783"=>770, "838"=>211, "750"=>749, "805"=>588, "827"=>107, "706"=>726, "784"=>31, "839"=>164, "751"=>102, "773"=>81, "795"=>1, "707"=>768, "817"=>568, "730"=>181, "785"=>161, "807"=>692, "719"=>470, "796"=>53, "708"=>153, "818"=>273, "786"=>978, "841"=>619, "742"=>413, "731"=>606}
    ilab.add_result_set('ql.res' , 'ql' ){|l| h[l[0]] }
    ilab.add_result_set('dm.res' , 'dm' ){|l| h[l[0]] }
    ilab.add_result_set($file_qrel , 'rel_o' ){|l| h[l[0]] && l[3].to_i > 0 }
    ilab.add_relevant_set($file_qrel_aw){|l| h[l[0]] }
  when 'set'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql.res' , 'ql' ){|l| !h[l[0]] }
    ilab.add_result_set('dm.res' , 'dm' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    ilab.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'setjm'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql_j00.res' , 'ql_j00' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j01.res' , 'ql_j01' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j03.res' , 'ql_j03' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j06.res' , 'ql_j06' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    ilab.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'setdir'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql_d500.res' , 'ql_d500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d1500.res' , 'ql_d1500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d3000.res' , 'ql_d3000' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    ilab.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'aw'
    # $query_allwords = $work_path+'/template_query_allwords.rhtml'
    ilab.crt_add_query_set('allwords' , :template=>:allwords ) # {|e|e =~ /^ca/}
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql.res' , 'ql' ){|l| !h[l[0]] }
    ilab.add_result_set('dm.res' , 'dm' ){|l| !h[l[0]] }
    ilab.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
  when 'awjm'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql_j00.res' , 'ql_j00' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j01.res' , 'ql_j01' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j03.res' , 'ql_j03' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_j06.res' , 'ql_j06' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
    ilab.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }
  when 'awmdir'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql_mdir_1500_500.res' , 'ql_mdir_1500_500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_mdir_1500_1000.res' , 'ql_mdir_1500_1000' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_mdir_1500_1500.res' , 'ql_mdir_1500_1500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d1500.res' , 'ql_d1500' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
    ilab.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }

  when 'setmdir'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set('ql_mdir_1500_250.res' , 'ql_mdir_1500_250' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_mdir_1500_500.res' , 'ql_mdir_1500_500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_mdir_1500_1000.res' , 'ql_mdir_1500_1000' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_mdir_1500_1500.res' , 'ql_mdir_1500_1500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d500.res' , 'ql_d500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d1500.res' , 'ql_d1500' ){|l| !h[l[0]] }
    ilab.add_result_set('ql_d3000.res' , 'ql_d3000' ){|l| !h[l[0]] }
    ilab.add_result_set($file_qrel_aw , 'allwords'){|l| !h[l[0]] }
    ilab.add_relevant_set($file_qrel ){|l| !h[l[0]] && l[3].to_i > 0}

  when 'awdir'
    h = {"832"=>false , "749"=>false}
    ilab.add_result_set($file_qrel , 'rel_o' ){|l| !h[l[0]] && l[3].to_i > 0}
    ilab.add_relevant_set($file_qrel_aw){|l| !h[l[0]] }

  when 'dir_prior'
    #ilab.crt_add_query_set('ql_d500_pprob' , :smoothing=>'method:dirichlet,mu:500,operator:term' , :prior=>'prob')
    #ilab.crt_add_query_set('ql_d1500_pprob'  , :prior=>'prob')
    #ilab.crt_add_query_set('ql_d3000_pprob' , :smoothing=>'method:dirichlet,mu:3000,operator:term' , :prior=>'prob')
    #ilab.crt_add_query_set('ql_d4500_pprob' , :smoothing=>'method:dirichlet,mu:4500,operator:term' , :prior=>'prob')
    ilab.crt_add_query_set('ql_d500_plen' , :smoothing=>'method:dirichlet,mu:500,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_d1500_plen'  , :prior=>'length')
    ilab.crt_add_query_set('ql_d3000_plen' , :smoothing=>'method:dirichlet,mu:3000,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_d4500_plen' , :smoothing=>'method:dirichlet,mu:4500,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_d500' , :smoothing=>'method:dirichlet,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_d1500' )
    ilab.crt_add_query_set('ql_d3000' , :smoothing=>'method:dirichlet,mu:3000,operator:term' )
    ilab.crt_add_query_set('ql_d4500' , :smoothing=>'method:dirichlet,mu:4500,operator:term' )
    ilab.add_relevant_set($file_qrel)

  when 'dir_fusion'
    ilab.crt_add_query_set('ql_d500' , :smoothing=>'method:dirichlet,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_d1500' )
    ilab.crt_add_query_set('ql_d3000' , :smoothing=>'method:dirichlet,mu:3000,operator:term' )
    ilab.crt_add_query_set('ql_d4500' , :smoothing=>'method:dirichlet,mu:4500,operator:term' )
    ['CombSUM','CombMNZ','NCombSUM','NCombMNZ'].each do |e|
      ResultDocumentSet.create_by_fusion("dir_f_#{e}" , ilab.rsa , :mode=>e) unless ilab.fcheck("dir_f_#{e}.res")
      ilab.crt_add_query_set("dir_f_#{e}" )
    end
    ilab.add_relevant_set($file_qrel)

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

  when 'jm_desc'
    ilab.crt_add_query_set('ql_j0001_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:jm,lambda:0.001,operator:term' )
    ilab.crt_add_query_set('ql_j02_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:jm,lambda:0.2,operator:term' )
    ilab.crt_add_query_set('ql_j04_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:jm,lambda:0.4,operator:term' )
    ilab.crt_add_query_set('ql_j06_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    ilab.crt_add_query_set('ql_j08_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:jm,lambda:0.8,operator:term' )

    ilab.crt_add_query_set('ql_j0001' , :smoothing=>'method:jm,lambda:0.001,operator:term' )
    ilab.crt_add_query_set('ql_j02' , :smoothing=>'method:jm,lambda:0.2,operator:term' )
    ilab.crt_add_query_set('ql_j04' , :smoothing=>'method:jm,lambda:0.4,operator:term' )
    ilab.crt_add_query_set('ql_j06' , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    ilab.crt_add_query_set('ql_j08' , :smoothing=>'method:jm,lambda:0.8,operator:term' )
    ilab.add_relevant_set($file_qrel)

  when 'jm_prior'
    #ilab.crt_add_query_set('ql_j0001_pprob' , :smoothing=>'method:jm,lambda:0.001,operator:term' , :prior=>'prob')
    #ilab.crt_add_query_set('ql_j03_pprob' , :smoothing=>'method:jm,lambda:0.3,operator:term' , :prior=>'prob')
    #ilab.crt_add_query_set('ql_j06_pprob' , :smoothing=>'method:jm,lambda:0.6,operator:term' , :prior=>'prob')
    #ilab.crt_add_query_set('ql_j09_pprob' , :smoothing=>'method:jm,lambda:0.9,operator:term' , :prior=>'prob')
    ilab.crt_add_query_set('ql_j0001_plen' , :smoothing=>'method:jm,lambda:0.001,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_j03_plen' , :smoothing=>'method:jm,lambda:0.3,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_j06_plen' , :smoothing=>'method:jm,lambda:0.6,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_j09_plen' , :smoothing=>'method:jm,lambda:0.9,operator:term' , :prior=>'length')
    ilab.crt_add_query_set('ql_j0001' , :smoothing=>'method:jm,lambda:0.001,operator:term' )
    ilab.crt_add_query_set('ql_j03' , :smoothing=>'method:jm,lambda:0.3,operator:term' )
    ilab.crt_add_query_set('ql_j06' , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    ilab.crt_add_query_set('ql_j09' , :smoothing=>'method:jm,lambda:0.9,operator:term' )
    ilab.add_relevant_set($file_qrel)

  when 'jm'
    ilab.crt_add_query_set('ql_j0001' , :smoothing=>'method:jm,lambda:0.001,operator:term' )
    ilab.crt_add_query_set('ql_j03' , :smoothing=>'method:jm,lambda:0.3,operator:term' )
    ilab.crt_add_query_set('ql_j06' , :smoothing=>'method:jm,lambda:0.6,operator:term' )
    ilab.crt_add_query_set('ql_j09' , :smoothing=>'method:jm,lambda:0.9,operator:term' )
    ilab.add_relevant_set($file_qrel)
    
  when 'two'
    ilab.crt_add_query_set('ql_two500-03_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.3,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_two500-05_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.5,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-01_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.1,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-03_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.3,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-05_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.5,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-07_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.7,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two2500-03_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.3,mu:2500,operator:term' )
    ilab.crt_add_query_set('ql_two2500-05_desc' , :topic_pattern=>$ptn_qry_desc , :smoothing=>'method:two,lambda:0.5,mu:2500,operator:term' )
    ilab.crt_add_query_set('ql_two500-03' , :smoothing=>'method:two,lambda:0.3,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_two500-05' , :smoothing=>'method:two,lambda:0.5,mu:500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-01' , :smoothing=>'method:two,lambda:0.1,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-03' , :smoothing=>'method:two,lambda:0.3,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two1500-05' , :smoothing=>'method:two,lambda:0.5,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_two2500-03' , :smoothing=>'method:two,lambda:0.3,mu:2500,operator:term' )
    ilab.crt_add_query_set('ql_two2500-05' , :smoothing=>'method:two,lambda:0.5,mu:2500,operator:term' )
    ilab.add_relevant_set($file_qrel)
  when 'mdir'
    #ilab.crt_add_query_set('ql_mdir_500_500' , :smoothing=>'method:two,lambda:0.0,mu:500,mindlen:500,operator:term' )
    #ilab.crt_add_query_set('ql_mdir_1500_250' , :smoothing=>'method:two,lambda:0.0,mu:1500,mindlen:250,operator:term' )
    ilab.crt_add_query_set('ql_mdir_1500_500' , :smoothing=>'method:two,lambda:0.0,mu:1500,mindlen:500,operator:term' )
    ilab.crt_add_query_set('ql_mdir_1500_1000' , :smoothing=>'method:two,lambda:0.0,mu:1500,mindlen:1000,operator:term' )
    ilab.crt_add_query_set('ql_d1500' )
    ilab.add_relevant_set($file_qrel)
  when 'opt'
    ilab.crt_add_query_set("optimized#{$o[:range]}#{$remark}" , :smoothing=>$param_opt, :range=>$o[:range])
    ilab.crt_add_query_set("ql_d1500_in#{$o[:range]}#{$remark}" , :smoothing=>$param_dir , :range=>$o[:range])
    ilab.crt_add_query_set("ql_d1500#{$o[:range]}#{$remark}" , :range=>$o[:range])
    #ilab.crt_add_query_set("optimized2" , :smoothing=>$param_opt2)
    #ilab.crt_add_query_set("ql_j03#{$o[:range]}" , :smoothing=>"method:jm,lambda:0.3,operator:term", :range=>$o[:range] )
    ilab.add_relevant_set($file_qrel)
  when 'opt_test'
    #info $o
    remote_query=true
    ptn_qry = get_ptn_query($qry_type)
    ilab.crt_add_query_set("optimized_intrpl_test_#{$qry_type}#{$o[:cval_id]}_#{$o[:cval_no]}#{$remark}#{($o[:step])? "step":""}" , ptn_qry , :smoothing=>$param_opt+",step:false" , :range=>$range_test , :remote_query=>remote_query, :redo=>$o[:redo])
    ilab.crt_add_query_set("optimized_step_test_#{$qry_type}#{$o[:cval_id]}_#{$o[:cval_no]}#{$remark}#{($o[:step])? "step":""}" , ptn_qry , :smoothing=>$param_opt+",step:true" , :range=>$range_test , :remote_query=>remote_query, :redo=>$o[:redo])
    ilab.crt_add_query_set("ql_d1500_test_#{$qry_type}#{$o[:cval_no]}#{$o[:cval_id]}" , ptn_qry , :range=>$range_test , :remote_query=>remote_query, :redo=>$o[:redo])
    ilab.crt_add_query_set("ql_j03_test_#{$qry_type}#{$o[:cval_no]}#{$o[:cval_id]}" , ptn_qry , :smoothing=>'method:jm,lambda:0.3,operator:term' , :range=>$range_test , :remote_query=>remote_query, :redo=>$o[:redo])
    ilab.add_relevant_set($file_qrel)
  when 'cmp_smt'
    #ilab.crt_add_query_set('dm_o'  , :template=>:dm )
    ilab.crt_add_query_set('ql_two1500-03' , :smoothing=>'method:two,lambda:0.3,mu:1500,operator:term' )
    ilab.crt_add_query_set('ql_d1500' )
    ilab.crt_add_query_set('ql_j01' , :smoothing=>'method:jm,lambda:0.1,operator:term' )
    ilab.add_relevant_set($file_qrel)
  when 'qldm_ns'
    ilab.crt_add_query_set('ql_o' )
    ilab.crt_add_query_set('dm_o'  , :template=>:dm )
    ilab.crt_add_query_set('ql_ns' )
    ilab.crt_add_query_set('dm_ns'  , :template=>:dm )
    #ilab.crt_add_query_set('narr' , $ptn_qry_narr )
    #ilab.crt_add_query_set('desc' , $ptn_qry_desc )
    ilab.add_relevant_set($file_qrel)
    #ilab.run_query_set('topic')
  when 'qldm'
    ilab.crt_add_query_set('ql' )
    ilab.crt_add_query_set('dm'  , :template=>:dm )
=begin
    ['NCombSum','CombSUM','CombMNZ'].each do |e|
      ResultDocumentSet.create_by_fusion("qldm_f_#{e}" , ilab.rsa , :mode=>e) unless ilab.fcheck("qldm_f_#{e}.res")
      ilab.crt_add_query_set("qldm_f_#{e}" )
    end
=end
    ilab.add_relevant_set($file_qrel)


  #
  when 'range_opt'
    no_len_points = $o[:set_no] || 5 ; tgt_set = $o[:set_id] || 0
    $qs = []  ; remote_query=false
    info "tgt_set = #{tgt_set}"
    #Local Retrieval
    length_points = ilab.get_length_points( no_len_points ) ; puts "length_points : #{length_points.inspect}"
    length_points.map_cons(2).each_with_index do |r,i|
      next if i != tgt_set
      $qs[i] = {}
      [:ql,:dm].each do |retr|
        [0.1,0.3,0.5,0.7,0.9].each do |ld|
          $qs[i][[retr,ld].join]  = ilab.crt_add_query_set("jm_#{r[0]}_#{r[1]}_#{retr}_ld#{ld}" , :minDocLen=>r[0] , :maxDocLen=>r[1] , :smoothing=>"method:jm,lambda:#{ld},operator:term" , :template=>retr , :remote_query=>remote_query )
        end
        [500,1500,2500,3000,4500].each do |mu|
          $qs[i][[retr,mu].join]  = ilab.crt_add_query_set("dr_#{r[0]}_#{r[1]}_#{retr}_mu#{mu}" , :minDocLen=>r[0] , :maxDocLen=>r[1] , :mu=>mu, :smoothing=>"method:dirichlet,mu:#{mu},operator:term" , :template=>retr , :remote_query=>remote_query )
        end
      end
    end
    ilab.add_relevant_set($file_qrel)

  #Locally Optimized Run vs. Local Sample of Globally Optimized Run
  when 'range_dir'
    no_len_points = $o[:len_points] || 5 ; topk = $topk || 10 ; count = no_len_points * 3000
    tgt_set = 0 || $o[:tgt_set] if $exp == 'document'
    $qs = [] ; $rs_max = [] ; remote_query=false
    
    #Global Retrieval
    qs_g = ilab.create_query_set("ql_d1500_#{count}", :docCount=>count, :smoothing=>"method:dirichlet,mu:1500,operator:term")
    ilab.length_stat_docset qs_g.rs
    #Local Retrieval
    length_points = ilab.get_length_points( no_len_points ) ; puts "length_points : #{length_points.inspect}"
    length_points.map_cons(2).each_with_index do |r,i|
      next if $exp == 'document' && i != tgt_set
      $qs[i] = {}
      [500,1500,2500,3000,4500].each do |mu|
        $qs[i][mu]  = ilab.create_query_set("dr_#{r[0]}_#{r[1]}_mu#{mu}" , :minDocLen=>r[0] , :maxDocLen=>r[1] , :mu=>mu, :smoothing=>"method:dirichlet,mu:#{mu},operator:term" , :remote_query=>remote_query )
      end
      ilab.add_query_set $qs[i].values.max{|a,b| a.stat['all']['P10'] <=> b.stat['all']['P10']}
      rs = ilab.add_result_set ResultDocumentSet.create_by_filter("dr_#{r[0]}_#{r[1]}_g", qs_g.rs) {|d| ((r[0]+1)...(r[1])) === d.size }
      rs.docs.group_by{|d|d.qid}.each{|k,v|err("qid=#{k} docs=#{v.size}") unless v.size >= topk}
      #rs.docs.group_by{|d|d.qid}.each{|k,v|raise DataError, "qid=#{k} docs=#{v.size}" unless v.size >= topk}
    end
    ilab.add_relevant_set($file_qrel)

  #Combination of Locally Optimized Runs vs. Globally Optimized Run
  when 'range_dir_com'
    no_len_points = $o[:len_points] || 5 ; topk = $topk || 20
    result_set_name = "dir_com_#{no_len_points}_#{topk}"
    if !ilab.fcheck("#{result_set_name}.res") || $exp == 'perf_length'
      $qs = [] ; $rs_max = [] ; remote_query=false
      
      #Get LenDIst of Relevant Set
      ilab.add_relevant_set($file_qrel)
      ilab.length_stat_docset ilab.rl

      length_points = ilab.get_length_points( no_len_points ) ; puts "length_points : #{length_points.inspect}"
      length_points.map_cons(2).each_with_index do |r,i|
        $qs[i] = {}
        [500,1500,2500,3000,4500].each do |mu|
          $qs[i][mu]  = ilab.create_query_set("ql_#{mu}_#{r[0]}_#{r[1]}" , :minDocLen=>r[0] , :maxDocLen=>r[1] , :mu=>mu, :smoothing=>"method:dirichlet,mu:#{mu},operator:term" , :remote_query=>remote_query )
        end
        $rs_max[i] = $qs[i].values.max{|a,b| a.stat['all']['map'] <=> b.stat['all']['map']}.rs
        # $rs_max[i].rank_limit = ilab.rl.ldist($o).to_p.find_all{|k,v| ((r[0]+1)...(r[1])) === k}.sum{|e|e[1]} * topk * no_len_points
        $rs_max[i].rank_limit = ilab.rl.docs.find_all{|d| ((r[0]+1)...(r[1])) === d.size}.size.to_f / ilab.rl.docs.size * topk * no_len_points
        info "rs_max[#{i}] = #{$rs_max[i].name} / rank_limit = #{$rs_max[i].rank_limit}"
        puts "[run.rb:range_dir] #{i}th thread ended!" if remote_query
      end
      rs_fusion = ResultDocumentSet.create_by_fusion(result_set_name , $rs_max){|e,ds|e.rank <= ds.rank_limit }
      rs_fusion.docs.group_by{|d|d.qid}.each{|k,v|err("qid=#{k} docs=#{v.size}") unless v.size == topk * no_len_points}
    end
    if $exp != 'perf_length'
      ilab.clear
      ilab.crt_add_query_set(result_set_name )
      ilab.crt_add_query_set('ql_d1500' )
      ilab.add_relevant_set($file_qrel)
    end
  else
  end#case
end
begin
  $i = ILabLoader.load($i)
rescue DataError
  puts 'Data inconsistency found while loading..'
  exit
end

#Choose Experiment
if !$exp
  if $method =~ /^aw/
    $exp = 'allwords'
  elsif $method =~ /^range/
    $exp = 'perf_length'
  elsif $method =~ /^set/
    $exp = 'set'
  else
    # $exp = 'query'
    $exp = 'length'
  end
end

if ['length','set','document'].include?($exp) or $o[:query_wise]
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
if $o[:env]
  $r[:expid] = get_expid_from_env()
  info("RETURN<#{$r.inspect}>RETURN")
end
info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
