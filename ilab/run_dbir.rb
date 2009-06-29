DEFAULT_ENGINE_TYPE = :indri
load 'ilab.rb'
#Set PATH
$exp_root = ENV['DI']
$r_path = ENV['R_PROJECT']
$indri_path = ENV['INDRI']
$lemur_path = ENV['LEMUR']
$trec_eval_path = ENV['WK']+'/app/trec_eval'

#Set Arguments
$o = {} if !defined?($o)
$topk = 10 if !$o[:topk]
$train = ($o[:train])? 't_' : ''
$i = ILab.new($col , get_opt_ilab($o)) 

#Set Global Vars
$t_start = Time.now

#Choose Collection
case $col
when 'monster'
  INDEX_PATH = '/work1/jykim/prj/dbir/monster/monster'
  INDEX_PATH_COARSE = '/work1/jykim/prj/dbir/monster/monster_coarse'
  $index_path = INDEX_PATH
  $i.config_path( :work_path=>$exp_root+'/monster' ,:index_path=>$index_path )
  $ptn_qry_title = /\<title\> (.*)/
  # $ptn_qry_title = /\<simple\>(.*?)\<\/simple\>/
  $file_topic = ($o[:train])? 'topics.41-60' : 'topics.01-40'
  $file_qrel = ($o[:train])? 'qrels.41-60' : 'qrels.01-40'
  $offset = ($o[:train])? 41 : 1
  $fields = ['resumetitle','summary','desiredjobtitle','schoolrecord','experiencerecord','location','skill','additionalinfo'] 
  $sparam = get_sparam('jm',0.5)
  $hlm_weight = [1.236067949688, 1.236067949688, 1.236067949688, 0.0, 1.05572805765242, 0.790243232371999, 0.901699407062102, 2.0]
  # [1.5, 1.1, 1.3, 2.0, 1.7, 0.6, 1.0, 0.5] #using s_neighbor
  # $hlm_weight = [1.0, 0.2, 1.0, 0.2, 0.2, 1.0, 0.5, 0.2]
  #$field_doc = 'DOC'
  $title_field = 'ResumeTitle'
when 'imdb'
  INDEX_PATH = '/work1/jykim/prj/dbir/imdb/index'
  INDEX_PATH_DUP = '/work1/jykim/prj/dbir/imdb/index_dup'
  INDEX_PATH_PLOT = '/work1/jykim/prj/dbir/imdb/index_plot'
  $index_path = INDEX_PATH_PLOT
  $i.config_path( :work_path=>$exp_root+'/imdb' ,:index_path=>$index_path )
  $file_topic = ($o[:train])? 'topics.041-050' : 'topics.001-040'
  $file_qrel = ($o[:train])? 'qrels.041-050' : 'qrels.001-040'
  $offset = ($o[:train])? 41 : 1
  $ptn_qry_title = /\<title\> (.*)/
  $fields = ['title','year','releasedate','language','genre', 'country','location','colorinfo','actors','team', 'plot']
  $sparam = get_sparam('jm',0.1)
  $sparam_fields = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.0, 0.2, 0.0] #[0.2,0.1,0.1,0.1,0.1, 0.1,0.1,0.1,0.1,0.1, 0.3]
  $hlm_weight = [1.9, 1.8, 0.1, 0.9, 0.9, 0.5, 0.5, 0.5, 0.6, 0.4, 0.2]
  $field_doc = 'movie'
  $title_field = 'title'
end

#Choose Retrieval Method
def ILabLoader.build(ilab)
  case $method
  when 'topic'
    $file_topic = 'topics.01-40.simple'
  #Different indexing method
  when 'indexing'
    sparam = get_sparam('jm',0.1)
    ilab.crt_add_query_set('idx', :index_path=>INDEX_PATH, :template=>:qfw, :smoothing=>sparam)
    ilab.crt_add_query_set('idx_dup', :index_path=>INDEX_PATH_DUP, :template=>:qfw, :smoothing=>sparam)
    ilab.crt_add_query_set('idx_plot', :index_path=>INDEX_PATH_PLOT, :template=>:qfw, :smoothing=>sparam)
  when 'topk_field' #How many TopK field to include in calc.
    [1,2,3,4,5].each do |n|
      # $topk_field = n
      ilab.crt_add_query_set("#{$train}PRM_top#{n}_field", :template=>:prm, :smoothing=>$sparam, :topk_field=>n)
    end
  #Smoothing parameter optimization
  when 'smt_cmp'
    [:ql,:prm].each do |retr|
      #ilab.crt_add_query_set("nosmt_#{retr}" , :smoothing=>nil , :template=>retr )
      [0.1,0.5,0.9].each do |ld|
        ilab.crt_add_query_set("#{$train}jm_#{retr}_ld#{ld}" , :smoothing=>get_sparam('jm',ld) , :template=>retr, :index_path=>($index_path+'_hci') )
      end
      [100,200].each do |mu|
       #ilab.crt_add_query_set("#{$train}dr_#{retr}_mu#{mu}" , :smoothing=>get_sparam('dirichlet',mu) , :template=>retr ) #if retr == :ql
      end
    end
  when 'smt_term'
    [:ql,:prm,:prm_phrase].each do |retr|
      [0.0,0.1,0.3,0.5,0.7,0.9].each do |ld|
        ilab.crt_add_query_set("#{$train}jm_#{retr}_ld#{ld}" , :smoothing=>get_sparam('jm',ld) , :template=>retr, :phrase_weight=>0.0 )
      end
      [5,10,50,100,250,500,1500,2500].each do |mu|
        ilab.crt_add_query_set("#{$train}dr_#{retr}_mu#{mu}" , :smoothing=>get_sparam('dirichlet',mu) , :template=>retr, :phrase_weight=>0.0 )
      end
    end
    smoothing = $fields.map_with_index{|f,i| get_sparam('jm', $sparam_fields[i], f)}
    ilab.crt_add_query_set("#{$train}fls_tew" , :smoothing=>smoothing , :template=>:prm )
  when 'smt_window'
    [:prms,:prm_phrase].reverse.each do |retr|
      [0.1,0.3,0.5,0.7,0.9].each do |ld|
        ilab.crt_add_query_set("#{$train}jm_#{retr}_ld#{ld}" , :smoothing=>[get_sparam('jm',0.1),get_sparam('jm',ld,nil,'window')] , :template=>retr )
      end
      [5,10,50,100,250,500,1500,2500,4000].each do |mu|
        ilab.crt_add_query_set("#{$train}dr_#{retr}_mu#{mu}" , :smoothing=>[get_sparam('jm',0.1),get_sparam('dirichlet',mu,nil,'window')] , :template=>retr )
      end
    end
  when 'prior_mp'
    ilab.crt_add_query_set("#{$train}DQL" ,:smoothing=>get_sparam('jm',0.5))
    ilab.crt_add_query_set("#{$train}PRM", :template=>:prm, :smoothing=>$sparam)
    [1.4,1.8].each do |pw|
      prior_weight = {'resumetitle'=>pw,'desiredjobtitle'=>pw}
      ilab.crt_add_query_set("#{$train}PRM_PW#{pw}", :template=>:prm, :smoothing=>$sparam, :prior_weight=>prior_weight)
    end
  when 'prior_len'
    [:ql,:prm].each do |retr|
      [nil,"length","length2","length3"].each do |pl|
        [0.1,0.3,0.5,0.7,0.9].each do |ld|
          ilab.crt_add_query_set("#{$train}#{retr}_ld#{ld}_pl#{pl}" , :smoothing=>[get_sparam('jm',ld)] , :template=>retr, :prior=>pl )
        end
      end
    end
  when 'phrase'
      ilab.crt_add_query_set("#{$train}PRM", :template=>:prm, :smoothing=>$sparam)
      ilab.crt_add_query_set("#{$train}PRMS", :template=>:prms, :smoothing=>[$sparam,get_sparam('jm', 0.1, nil, 'window')])
      ilab.crt_add_query_set("#{$train}PRMSB", :template=>:prms, :smoothing=>[$sparam,get_sparam('jm', 0.1, nil, 'window')], :binary_weight=>true)
      #ilab.crt_add_query_set("#{$train}PRM_DM", :template=>:prm_dm, :smoothing=>[$sparam,get_sparam('jm', 0.1, nil, 'window')])
      #Queryterm-wise Field Weighting
      #ilab.crt_add_query_set("#{$train}PRM_PHR_0", :template=>:prm_phrase, :smoothing=>[$sparam,get_sparam('jm', 0.1, nil, 'window')], :phrase_weight=>0.0)
      #ilab.crt_add_query_set("#{$train}PRM_PHR", :template=>:prm_phrase, :smoothing=>[$sparam,get_sparam('jm', 0.1, nil, 'window')])
  #Comparison w/ Baseline
  when 'word'
    ilab.crt_add_query_set("#{$train}DQL_WQ", :smoothing=>get_sparam('jm',0.5), :file_topic=>'topics.word')
    ilab.crt_add_query_set("#{$train}PRM_WQ", :template=>:prm, :smoothing=>get_sparam('jm',0.5), :file_topic=>'topics.word')
  when 'baseline'
    case $col
    when 'monster'
      #ilab.crt_add_query_set("#{$train}FLM", :template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weight=>[1.0]*$fields.size)
      ilab.crt_add_query_set("#{$train}HLM", :template=>:hlm, :smoothing=>get_sparam('jm',0.5), :hlm_weight=>$hlm_weight)
      ilab.crt_add_query_set("#{$train}DQL" ,:smoothing=>get_sparam('jm',0.5))
      #ilab.crt_add_query_set("#{$train}DQL_DM" , :template=>:dm, :smoothing=>[get_sparam('jm',0.5), get_sparam('jm', 0.1, nil, 'window')])
      #ilab.crt_add_query_set("#{$train}DQL_p" ,:smoothing=>get_sparam('jm',0.5),:prior=>'length')
      ilab.crt_add_query_set("#{$train}PRM", :template=>:prm, :smoothing=>get_sparam('jm',0.5))
      #ilab.crt_add_query_set("#{$train}PRM_p", :template=>:prm, :smoothing=>get_sparam('jm',0.5), :prior=>'length')
      #ilab.crt_add_query_set("#{$train}PRM_PW", :template=>:prm, :smoothing=>$sparam, :prior_weight=>{'resumetitle'=>1.4,'desiredjobtitle'=>1.4})
      #ilab.crt_add_query_set("#{$train}PRMS", :template=>:prms, :smoothing=>[get_sparam('jm',0.5), get_sparam('jm', 0.1, nil, 'window')])
      #ilab.crt_add_query_set("#{$train}PRM_DM", :template=>:prm_dm, :smoothing=>[get_sparam('jm',0.5), get_sparam('jm', 0.1, nil, 'window')])
      #ilab.crt_add_query_set("#{$train}BOW_SQ", :smoothing=>get_sparam('jm',0.5), :file_topic=>'topics.short')
      #ilab.crt_add_query_set("#{$train}PRM_SQ", :template=>:prm, :smoothing=>get_sparam('jm',0.5), :file_topic=>'topics.short')
    when 'imdb'
      #Full-text Query-likelihood
      #ilab.crt_add_query_set("#{$train}HLM", :template=>:hlm, :smoothing=>nil, :hlm_weight=>$hlm_weight)      
      ilab.crt_add_query_set("#{$train}DQL" ,:smoothing=>get_sparam('dirichlet',1500))
      ilab.crt_add_query_set("#{$train}HLM_x", :smoothing=>nil) #get_sparam('jm',0.1))
      #ilab.crt_add_query_set("#{$train}DQL_p" ,:smoothing=>get_sparam('jm',0.5),:prior=>'length')
      ilab.crt_add_query_set("#{$train}Manual_x", :smoothing=>get_sparam('jm',0.1))
      ilab.crt_add_query_set("#{$train}PRM", :template=>:prm, :smoothing=>get_sparam('jm',0.1))

      #ilab.crt_add_query_set("#{$train}PRM_p", :template=>:prm, :smoothing=>get_sparam('jm',0.5), :prior=>'length')
      #ilab.crt_add_query_set("#{$train}PRMS", :template=>:prms, :smoothing=>[get_sparam('jm',0.1), get_sparam('jm', 0.1, nil, 'window')])
      #ilab.crt_add_query_set("#{$train}PRM_DM", :template=>:prm_dm, :smoothing=>[get_sparam('jm',0.5), get_sparam('jm', 0.1, nil, 'window')])

      #sparam = [0.1]*11
      #sparam = [0.1,0.0,0.0,0.0,0.2, 0.0,0.2,0.0,0.05,0.15, 0.1]
      #smoothing = $fields.map_with_index{|f,i| get_sparam('jm', sparam[i], f)}
      #ilab.crt_add_query_set("#{$train}tew_fls" , :smoothing=>smoothing , :template=>:prm )
    end
  end#case
  if !ilab.fcheck($file_qrel) 
    warn "Create Qrel First!"
    $exp = 'qrel'
    return
  end
  ilab.add_relevant_set($file_qrel)      
  ilab.fetch_data
end

begin
  ['length','length2','length3'].each{|e| $engine.run_make_prior(e) }
  $i = ILabLoader.load($i)
rescue DataError
  puts 'Data inconsistency found while loading..'
  exit
end


#Run Experiment & Generate Report
$r = {}
info("Experiment '#{$exp}' started..")
eval IO.read(to_path('exp_'+$exp+'.rb'))
$i.create_report_index

info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
