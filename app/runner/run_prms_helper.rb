#include ReportHelper
def init_env()
  #Set PATH
  $exp_root = ENV['DH']
  $r_path = ENV['R_PROJECT']
  $indri_path = ENV['INDRI']
  $indri_path_dih = ENV['INDRI_DIH']
  $crfpp_path = ENV['CRFPP']
  $galago_path = ENV['GALAGO']+"/galagosearch-core/target/appassembler"
  $lemur_path = ENV['LEMUR']
  $trec_eval_path = ENV['INDRI']

  #Set Arguments
  #get_env_from_expid(ARGV[0]) if ARGV.size > 0
  $o = {} if !defined?($o)
  $topk = $o[:topk] || 10
  $i = ILab.new($col , get_opt_ilab($o)) 
  $r = $o.dup
  #$cf= {}
  $dflm = {} if !defined?($dflm)
  $dfv = {} if !defined?($dfv)
  $cf = {} if !defined?($cf)

  $dflms_rl = [] if !$dflms_rl
  $dflms_rs = [] if !$dflms_rs 

  $dlms_rs = [] if !$dlms_rs 
  
  #Set Global Vars
  $t_start = Time.now
  if $o[:col_type]
    $col_id = "#{$col}_#{$o[:pid]}_#{$o[:col_type]}"
  elsif $o[:col_id]
    $col_id = [$col,$o[:col_id]].join("_")
  else
    $col_id = $col
  end
  $o[:topic_id] = $o[:topic_type] if !$o[:topic_id] && $o[:topic_type]
  $query_prefix = "#{$col_id}_#{$o[:topic_id]}"
  $file_topic = ["topic", $col_id ,$o[:topic_id]].join("_")
  $file_qrel =  ["qrel" , $col_id, $o[:topic_id]].join("_")

  #Default Retrieval Parameter
  $mu = $o[:mu] || 100
  $lambda = $o[:lambda] || 0.1
  $k1 = $o[:k1] || 1.0
  $method = $exp if !$method
end

def init_collection(col)
  #Choose Collection
  case col
  when 'syn'
    col_path = "#$exp_root/#$col/raw_doc/#$col_id.trecweb"
    $index_path = "#$exp_root/#$col/index_#$col_id"
    $gindex_path = "#$exp_root/#$col/gindex_#$col_id"
    stemmer = nil
    field_no = 5
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    if !File.exist?(col_path)
      $engine.build_collection($col_id, 100, field_no, $o[:mix_ratio] || 0.5)
    end
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/
    $fields = (1..field_no).to_a.map{|i| "f#{i}" }
    if !File.exist?($index_path)#"#$exp_root/trec/raw_doc"
      $engine.build_index($col_id , col_path , $index_path , :fields=>$fields, :stemmer=>stemmer, :stopword=>false)
    end
    if !File.exist?($gindex_path)#
      $gengine.build_index($col_id , col_path , $gindex_path , :fields=>$fields, :stemmer=>stemmer, :stopword=>false)
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "f1"
    #Topic/Qrel Building
    if $o[:topic_type]
      $offset = 1 ; $count = $o[:topic_no] || 50
      $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
    else
      error "topic_type not specified!"
    end
  when 'trec'
    #$col_path = "#$exp_root/trec/raw_gdoc/wsj89_small.trectext"
    col_path = "#$exp_root/trec/raw_doc/lists_all.trecweb"
    $index_path = "#$exp_root/trec/index_lists"
    $gindex_path = "#$exp_root/trec/gindex_lists"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/
    $fields =  $o[:fields] || ['sent','name','email','subject','to','text']
    if !File.exist?($index_path)#"#$exp_root/trec/raw_doc"
      $engine.build_index($col_id , col_path , $index_path , :fields=>$fields, :stemmer=>'krovetz' , :stopword=>false)
    end
    if !File.exist?($gindex_path)#
      $gengine.build_index($col_id , col_path , $gindex_path , :fields=>$fields, :stemmer=>'porter', :stopword=>false)
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
    #Topic/Qrel Building
    if $o[:topic_type] == "MKV"
      $offset, $count = 1, 125
    elsif $o[:topic_type]
      $offset = 1 ; $count = $o[:topic_no] || 50
      $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
    else
      case $o[:topic_id]
      when 'train'
        $offset, $count = 1, 25
        $file_topic ,$file_qrel = 'ent05.known-item.training-topics' , 'ent05.known-item.training-qrels'
        $file_topic_train ,$file_qrel_train = 'ent05.known-item-topics', 'ent05.known-item-qrels'
      when 'test'
        $offset, $count = 26, 125
        $file_topic ,$file_qrel = 'ent05.known-item-topics', 'ent05.known-item-qrels'
        $file_topic_train ,$file_qrel_train = 'ent05.known-item.training-topics' , 'ent05.known-item.training-qrels'
      when 'all'
        $offset, $count = 1, 150
        $file_topic ,$file_qrel = 'ent05.known-item.topics.all' , 'ent05.known-item.qrels.all'
        $file_topic_train ,$file_qrel_train = $file_topic ,$file_qrel
      when 'cv21'
        $offset, $count = 1, 75
        $file_topic ,$file_qrel = 'ent05.topics.cv1', 'ent05.qrels.cv1'
        $file_topic_train ,$file_qrel_train = 'ent05.topics.cv2', 'ent05.qrels.cv2'
      when 'cv31'
        $offset, $count = 1, 100
        $file_topic ,$file_qrel = 'ent05.topics.cv312', 'ent05.qrels.cv312'
        $file_topic_train ,$file_qrel_train = 'ent05.topics.cv33', 'ent05.qrels.cv33'
        #$file_topic_valid ,$file_qrel_valid = 'ent05.topics.cv33', 'ent05.qrels.cv33'
      else
        $offset = 1
      #when 'MKV'
      #  $offset, $count = 26, 125
      #  $file_topic ,$file_qrel = 'topic_trec__MKV', 'qrel_trec__MKV'
      end
    end
    # Get Rdoc list (needed for oracle MP calculation)
    
  when 'facebook'
    $fields =  ["username", "message", "postctime", "postutime", "cmtname", "cmtmessage", "cmttime", "likename", "link", "description", "caption", "olink", "photoname", "albumname", "type", "count", "likes"]
    $ptn_qry_title = /[0-9]+\s(.*)/
    case $o[:topic_id]
    when 'fb2'
      $col_path, $index_path = "#$exp_root/facebook/Facebook-541120474-xmldoc", "#$exp_root/facebook/fb-user2"# "#$exp_root/facebook/index_fb2"
      $offset, $count = 2001, 36
      $file_topic ,$file_qrel = 'fbuser2.topic' , 'fbuser2.qrel'
    when 'fb3'
      $col_path, $index_path = "#$exp_root/facebook/Facebook-michael413-xmldoc", "#$exp_root/facebook/fb-user3"# "#$exp_root/facebook/index_fb3"
      $offset, $count = 3001, 62
      $file_topic ,$file_qrel = 'fbuser3.topic' , 'fbuser3.qrel'
    when 'fb4'
      $col_path, $index_path = "#$exp_root/facebook/Facebook-mcartright-xmldoc", "#$exp_root/facebook/fb-user4"# "#$exp_root/facebook/index_fb4"
      $offset, $count = 4001, 60
      $file_topic ,$file_qrel = 'fbuser4.topic' , 'fbuser4.qrel'
    end
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    if !File.exist?($index_path)
      $engine.build_index($col_id , $col_path , $index_path , :fields=>$fields, :stemmer=>'krovetz', :stopword=>false)
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "message"
  when 'twitter'
    $fields= ["cur_text", "cur_user", "cur_replyto", "cur_src", "cur_time", "olink", "re_text", "re_user", "re_replyto", "re_src", "re_time"]
    $ptn_qry_title = /[0-9]+\s(.*)/
    case $o[:topic_id]
    when 'tw1'
      $col_path, $index_path = "#$exp_root/twitter/Twitter-ldipillo89-xmldoc", "#$exp_root/twitter/tw-user1"# "#$exp_root/twitter/index_tw1"
      $offset, $count = 1101, 58
      $file_topic ,$file_qrel = 'twuser1.topic' , 'twuser1.qrel'
    when 'tw5'
      $col_path, $index_path = "#$exp_root/twitter/Twitter-JamieZieder-xmldoc", "#$exp_root/twitter/tw-user5"# "#$exp_root/twitter/index_tw5"
      $offset, $count = 5101, 50
      $file_topic ,$file_qrel = 'twuser5.topic' , 'twuser5.qrel'
    when 'tw6'
      $col_path, $index_path = "#$exp_root/twitter/Twitter-ronyar99-xmldoc", "#$exp_root/twitter/tw-user6"# "#$exp_root/twitter/index_tw6"
      $offset, $count = 6101, 62
      $file_topic ,$file_qrel = 'twuser6.topic' , 'twuser6.qrel'
    end
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    if !File.exist?($index_path)
      $engine.build_index($col_id , $col_path , $index_path , :fields=>$fields, :stemmer=>'krovetz', :stopword=>false)
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "message"
  when 'enron'
    $index_path = "#$exp_root/enron/index_enron"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /\<title\>\s(.*)\s\<\/title\>/
    $fields =  ['subject','from','to','date','body']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/enron/raw_doc" , $index_path , :fields=>$fields, :stemmer=>:krovetz, :stopword=>false)
    end
    case $o[:topic_id]
    when 'all'
      $offset, $count = 1, 214
      $file_topic ,$file_qrel = 'queries.all' , 'qrels.all'
    when 'test'
      $offset, $count = 1, 150
      $file_topic ,$file_qrel = 'queries.test' , 'qrels.test'
    when 'train'
      $offset, $count = 151, 64
      $file_topic ,$file_qrel = 'queries.train' , 'qrels.train'
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
    
  when 'enron2'
    $index_path = "#$exp_root/enron2/index_enron"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /\<title\>\s(.*)\s\<\/title\>/
    $fields =  ['subject','person','date','body']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/enron2/raw_doc" , $index_path , :fields=>$fields, :stemmer=>:krovetz, :stopword=>false)
    end
    case $o[:topic_id]
    when 'all'
      $offset, $count = 1, 214
      $file_topic ,$file_qrel = 'queries.all' , 'qrels.all'
    when 'test'
      $offset, $count = 1, 150
      $file_topic ,$file_qrel = 'queries.test' , 'qrels.test'
    when 'train'
      $offset, $count = 151, 64
      $file_topic ,$file_qrel = 'queries.train' , 'qrels.train'
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"

  when 'rexa'
    $index_path = "#$exp_root/rexa/index_rexa"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /\<query.*?\>\s(.*)\s\<\/query\>/
    $fields =  ['title','author','abstract','pages','year','journal','conference','booktitle','institution']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/rexa/rexa_docs" , $index_path , :fields=>$fields, :stemmer=>:krovetz, :stopword=>false)
    end
    case $o[:topic_id]
    when 'all'
      $offset, $count = 1, 648
      $file_topic ,$file_qrel = 'rexa_query' , 'rexa_qrel'
    when 'test'
      $offset, $count = 1, 150
      $file_topic ,$file_qrel = 'queries.test' , 'qrels.test'
    when 'train'
      $offset, $count = 151, 64
      $file_topic ,$file_qrel = 'queries.train' , 'qrels.train'
    end
    $sparam = get_sparam('jm',0.1)
    $title_field = "title"
    
  when 'imdb'
    $index_path = "#$exp_root/imdb/#{$o[:index_path] || 'index_noplot'}"
    $i.config_path( :work_path=>$exp_root+'/imdb' ,:index_path=>$index_path )
    $ptn_qry_title = ($o[:topic_id] =~ /^d/)? /\<title\> (.*)/ : /\<title\> (.*) \<\/title\>/
    $fields = ['title','year','releasedate','language','genre', 'country','location','colorinfo','actors','team'] #,'plot'
    case $o[:topic_id]
    when 'qtest'
      $offset, $count = 1, 1000
      $file_topic ,$file_qrel = 'queries.test' , 'qrels.test'
    when 'qtrain'
      $offset, $count = 1, 100
      $file_topic ,$file_qrel = 'queries.train' , 'qrels.train'
    when 'dtest'
      $offset, $count = 1, 40
      $file_topic ,$file_qrel = 'topics.001-040' , 'qrels.001-040'
    when 'dtrain'
      $offset, $count = 41,10
      $file_topic ,$file_qrel = 'topics.041-050' , 'qrels.041-050'
    when 'dcv1'
      $offset, $count = 1, 25
      $file_topic ,$file_qrel = 'topics.1' , 'qrels.1'
    when 'dcv2'
      $offset, $count = 26,25
      $file_topic ,$file_qrel = 'topics.2' , 'qrels.2'
    end
    $title_field = 'title'
    
  when 'imdbx'
    $index_path = "#$exp_root/imdbx/#{$o[:index_path] || 'index'}"
    $i.config_path( :work_path=>$exp_root+'/imdbx' ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\>(.*)\<\/title\>/
    $fields = ['title','releasedates','director','genre','actors','overview','cast',
      'additional_details', 'fun_stuff', 'name','year','overview','filmography'] #
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/imdbx/col_new" , $index_path , 
        :fields=>$fields, :stemmer=>:krovetz, :stopword=>false)
    end
    case $o[:topic_id]
    when 'test'
      $offset, $count = 2011101, 45
      $file_topic ,$file_qrel = '2011-dc-topics-adhocsearch-v3.xml', '2011-dc-article-v2.qrels.txt'
    end
    $title_field = 'title'
  
  when 'monster'
    $index_path = "#$exp_root/monster/#{$o[:index_path] || 'index'}"
    $i.config_path( :work_path=>$exp_root+'/monster' ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\> (.*)/
    $fields = ['resumetitle','summary','desiredjobtitle','schoolrecord','experiencerecord','location','skill','additionalinfo'] 
    case $o[:topic_id]
    when 'test'
      $offset, $count = 1, 40
      $file_topic ,$file_qrel = 'topics.01-40' , 'qrels.01-40'
    when 'train'
      $offset, $count = 41,20
      $file_topic ,$file_qrel = 'topics.41-60' , 'qrels.41-60'
    when 'cv1'
      $offset, $count = 1, 30
      $file_topic ,$file_qrel = 'topics.1' , 'qrels.1'
    when 'cv2'
      $offset, $count = 31,30
      $file_topic ,$file_qrel = 'topics.2' , 'qrels.2'
    end
    $title_field = 'resumetitle'
  end#case
  $bm25f_path = to_path("#{$query_prefix}_bm25f.in")
  $engine.init_kstem($file_topic)
  $rlflms1 = $engine.get_rel_flms_multi($file_qrel, 10) if !$rlflms1
  $queries =  $i.parse_topic_file($file_topic, $ptn_qry_title)
  $engine.init_kstem($file_topic_train) if $file_topic_train
  $queries_train =  $i.parse_topic_file($file_topic_train, $ptn_qry_title) if $file_topic_train
end


def set_collection_param(col_id)
  case col_id
  when 'trec'
    $sparam = get_sparam('jm',0.1)
    $sparam_prm = get_sparam('jm',0.1)
    $sparam_mflm = get_sparam('jm',0.1)
    
    $mix_weights = case $o[:mp_types]
    when [:cug, :cbg, :prior ]
      [0.01, 0.388, 0.388]	
    when [:rug, :rbg , :prior]
      [0.01, 0.388, 0.244]
    when [:cug, :cbg, :rug, :rbg]
      [0.01, 0.388, 1.0, 1.0]	
    when [:cug, :rug , :prior]
      [0.388, 0.388, 0.388]	
    else
      [0.01, 1.0, 0.154, 0.189, 0.099]	#(cosim/test)
      [0.388, 0.01, 1.0, 0.388, 1.0]	#(map/train)
      [0.01, 0.01, 0.856, 1.0, 0.388]	#(map/train/0926)
      #[0.01, 1.0, 0.154, 0.189, 0.099]	#(cosim/test)
      #[0.099, 1.0, 0.099, 0.01, 0.333]	#(cosim/train)
      #[0.01, 0.065, 1.0, 0.244, 1.0] #(map/test)
    end
    $mix_weights_reg = [0.096835, 0.663177, 0.045236, 0.018065, 0.182498]
    #['sent','name','email','subject','to','text'] <= ['subject','text','to','sent','name','email']
    $hlm_weight = $o[:hlm_weight] || [0.0,0.0,0.0,2.0,0.0,0.652].to_p #[2.0, 0.652, 0.0, 0.0, 0.0, 0.0]#[0.1,0.1,0.5,0.1,0.3];
    $mus = [2.631, 6.386, 18.034, 1.626, 3.947, 6.386] #[3.44418499304202, 4.25724680243181, 13.2742407237162, 20.1626111634632, 3.44418499304202, 0.0]
    $prmd_lambda = 0.7
    $bfs = [0.146, 0.236, 0.146, 0.0, 0.382, 0.133] 
    $bm25f_weight = [0.236, 0.674, 0.146, 1.0, 0.146, 0.09]
    $bs = [0.0, 0.138, 0.382, 0.0, 0.382, 0.0]
    $bm25_weight = [0.382, 0.382, 0.0, 0.382, 0.382, 0.0]
    
    # OLD Parameters
    $bfs = [0.0, 0.188, 0.0, 0.0, 0.0, 0.549]
    $bm25f_weight = [0.18, 1.0, 0.0, 1.0, 0.18, 0.292]

  when 'enron'
    $sparam = get_sparam('jm',0.1)#
    $sparam_prm = get_sparam('jm',0.1)#
    $sparam_mflm = get_sparam('jm',0.1)#
    
    $mix_weights = [0.01, 0.388, 0.388, 0.477, 0.189]
    #[0.01, 0.388, 0.388, 0.477, 0.189]	#(map/train)
    #[0.154, 1.0, 0.01, 0.01, 0.299] #(cosim/train)???
    
    $hlm_weight = [0.674, 0.562, 0.562, 0.146, 0.472]
    $prmd_lambda = 0.7

  when 'enron2'
    $sparam = get_sparam('jm',0.1)#
    $sparam_prm = get_sparam('jm',0.1)#
    $sparam_mflm = get_sparam('jm',0.1)#
    
    $mix_weights = [0.01, 1.0, 0.01, 0.01, 0.244]	# cps
    $mix_weights = [0.01, 0.01, 0.677, 0.477, 0.388]	# map
    
    $hlm_weight = [0.5] * $fields.size
    $prmd_lambda = 0.7
    
  when 'rexa'
    $sparam = get_sparam('jm',0.1)#
    $sparam_prm = get_sparam('jm',0.1)#
    $sparam_mflm = get_sparam('jm',0.1)#

    #$mix_weights = [0.01, 1.0, 0.01, 0.01, 0.244]	# cps
    #$mix_weights = [0.01, 0.01, 0.677, 0.477, 0.388]	# map

    #$hlm_weight = [0.5] * $fields.size
    #$prmd_lambda = 0.7

  when 'imdb'
    $sparam = get_sparam('dirichlet',1000)
    $sparam_prm = get_sparam('jm',0.1)#get_sparam('dirichlet',250)
    $sparam_mflm = get_sparam('jm',0.3)#get_sparam('dirichlet',50)
    
    case $o[:topic_id]
    when "dcv1"
      $mix_weights = [0.766, 0.422, 1.0, 0.01, 1.0]	# (cos)
      $mix_weights = [0.388, 0.388, 0.388, 0.01, 0.388]	#map
    when "dcv2"
      $mix_weights = [0.333, 1.0, 0.299, 0.01, 0.01]	# (cos)
      $mix_weights = [0.388, 0.388, 0.388, 0.388, 0.388] # (map)
    else
      $mix_weights = [0.333, 0.299, 1.0, 0.01, 1.0]	 # (cos/qtest)
      $mix_weights = [0.01, 0.388, 0.388, 0.01, 0.388]	# (MAP/dtrain/0926)
    end
    $mix_weights_reg = [0.49408, 0.50985, 0.49118, 0.07905, 0.63428]
    $bfs = [1.0, 0.562, 0.0, 0.146, 0.146, 0.146, 0.236, 0.146, 0.008, 0.459]
    $bm25f_weight = [1.0, 0.0, 0.236, 0.146, 0.146, 0.146, 0.146, 1.0, 0.472, 0.0]
    $hlm_weight = [1.9, 1.8, 0.1, 0.9, 0.9, 0.5, 0.5, 0.5, 0.6, 0.4]
    #$mix_weights = [0.388, 1.0, 0.388, 0.567, 0.388]	#[0.388, 0.01, 0.388, 0.622, 0.388]	
    #$mix_weights = [0.333, 0.299, 1.0, 0.01, 1.0]	
    #[0.388, 0.01, 0.388, 0.622, 0.388]	# (map/qtrain)
    #[0.388, 0.01, 0.388, 0.01, 0.388] # (map/dtrain)
    #[0.333, 0.299, 1.0, 0.01, 1.0]	 # (cos/qtest)

  when 'monster'
    $sparam = get_sparam('jm',0.5)
    $sparam_prm = get_sparam('jm',0.5)
    $sparam_mflm = get_sparam('jm',0.5)
    $hlm_weight = [1.236, 1.236, 1.236, 0.0, 1.055, 0.790, 0.901, 2.0]
    
    case $o[:topic_id]
    when "cv1"
      $mix_weights = [0.8, 1.0, 0.01, 0.01, 0.099]		# (cos)
      #$mix_weights = [0.01, 0.477, 0.567, 0.333, 0.01]	 # (map)
    when "cv2"
      $mix_weights = [1.0, 0.533, 0.01, 0.01, 0.099]		# (cos)
      #$mix_weights = [1.0, 0.388, 0.677, 0.01, 0.299]	 # (map)      
    else
      $mix_weights = [1.0, 0.477, 0.154, 0.01, 0.01]
    end
    $mix_weights = [1.0, 0.477, 0.154, 0.01, 0.01]
    $mix_weights_reg = [0.370411, 0.463172, -0.026643, 0.003014, 0.136356]
    $bfs = [0.674, 0.533, 0.146, 0.687, 0.0, 0.674, 0.353, 0.846]
    $bm25f_weight = [1.0, 0.528, 1.0, 0.292, 0.146, 0.146, 1.0, 1.0]
    $bm25f_weight = [0.562, 0.0, 0.472, 0.0, 0.674, 0.236, 0.146, 0.5] #0929
    $bm25f_weight = [0.798, 0.146, 1.0, 0.0, 1.0, 0.472, 0.292, 0.5] #0930
    #[1.0, 0.01, 0.333, 0.01, 0.01]	# (map/train)
    #[1.0, 0.477, 0.154, 0.01, 0.01] # (cos/train)
  end
end
