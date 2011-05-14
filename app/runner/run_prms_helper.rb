#include ReportHelper
def init_env()
  #Set PATH
  $exp_root = ENV['DH']
  $r_path = ENV['R_PROJECT']
  $indri_path = ENV['INDRI']
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
    $fields =  ['sent','name','email','subject','to','text']
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
      when 'test'
        $offset, $count = 26, 125
        $file_topic ,$file_qrel = 'ent05.known-item-topics', 'ent05.known-item-qrels'
      else
        $offset = 1
      #when 'MKV'
      #  $offset, $count = 26, 125
      #  $file_topic ,$file_qrel = 'topic_trec__MKV', 'qrel_trec__MKV'
      end
    end
    # Get Rdoc list (needed for oracle MP calculation)
    
  when 'enron'
    $index_path = "#$exp_root/enron/index_enron"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/
    $offset = 201
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
    end
    $title_field = 'resumetitle'
  end#case
  $engine.init_kstem($file_topic)
  $rlflms1 = $engine.get_rel_flms_multi($file_qrel)if !$rlflms1
  $queries =  $i.parse_topic_file($file_topic, $ptn_qry_title)
end


def set_collection_param(col_id)
  case col_id
  when 'trec'
    $sparam = get_sparam('jm',0.1)
    $sparam_prm = get_sparam('jm',0.1)
    $sparam_mflm = get_sparam('jm',0.1)
    
    $mix_weights = [0.388, 0.01, 1.0, 0.388, 1.0]
    #[0.01, 1.0, 0.154, 0.189, 0.099]	#(cosim/test)
    #[0.099, 1.0, 0.099, 0.01, 0.333]	#(cosim/train)
    #[0.388, 0.01, 1.0, 0.388, 1.0]	#(map/train)
    #[0.01, 0.065, 1.0, 0.244, 1.0] #(map/test)
    #['sent','name','email','subject','to','text'] <= ['subject','text','to','sent','name','email']
    $hlm_weight = [0.0,0.0,0.0,2.0,0.0,0.652].to_p #[2.0, 0.652, 0.0, 0.0, 0.0, 0.0]#[0.1,0.1,0.5,0.1,0.3];
    $mus = [2.631, 6.386, 18.034, 1.626, 3.947, 6.386]#[3.44418499304202, 4.25724680243181, 13.2742407237162, 20.1626111634632, 3.44418499304202, 0.0]
    $prmd_lambda = 0.7
    $bfs = [0.0, 0.549, 0.0, 0.0, 0.188, 0.0]#[0.0, 0.541019645878629, 0.0, 0.0, 0.291796053982211, 0.0]
    $bm25f_weight = [1.0, 0.292, 0.18, 0.18, 1.0, 0.0]
    $bs = [0.0, 0.138, 0.382, 0.0, 0.382, 0.0]
    $bm25_weight = [0.382, 0.382, 0.0, 0.382, 0.382, 0.0]

  when 'enron'
    $sparam = get_sparam('jm',0.1)#
    $sparam_prm = get_sparam('jm',0.1)#
    $sparam_mflm = get_sparam('jm',0.1)#
    
    $mix_weights = [0.154, 1.0, 0.01, 0.01, 0.299]	
    #[0.01, 0.388, 0.388, 0.477, 0.189]	#(map/train)
    #[0.154, 1.0, 0.01, 0.01, 0.299] #(cosim/train)???
    
    $hlm_weight = [0.674, 0.562, 0.562, 0.146, 0.472]
    $prmd_lambda = 0.7

  when 'imdb'
    $sparam = get_sparam('dirichlet',1000)
    $sparam_prm = get_sparam('jm',0.1)#get_sparam('dirichlet',250)
    $sparam_mflm = get_sparam('jm',0.3)#get_sparam('dirichlet',50)
    $mix_weights = [0.388, 0.01, 1.0, 0.388, 1.0]
    $hlm_weight = [1.9, 1.8, 0.1, 0.9, 0.9, 0.5, 0.5, 0.5, 0.6, 0.4]
    $mix_weights = [0.388, 1.0, 0.388, 0.567, 0.388]	#[0.388, 0.01, 0.388, 0.622, 0.388]	
    $mix_weights = [0.333, 0.299, 1.0, 0.01, 1.0]	
    #[0.388, 0.01, 0.388, 0.622, 0.388]	# (map/qtrain)
    #[0.388, 0.01, 0.388, 0.01, 0.388] # (map/dtrain)
    #[0.333, 0.299, 1.0, 0.01, 1.0]	 # (cos/qtest)

  when 'monster'
    $sparam = get_sparam('jm',0.5)
    $sparam_prm = get_sparam('jm',0.5)
    $sparam_mflm = get_sparam('jm',0.5)
    $hlm_weight = [1.236, 1.236, 1.236, 0.0, 1.055, 0.790, 0.901, 2.0]
    $mix_weights = [1.0, 0.477, 0.154, 0.01, 0.01]	
    #[1.0, 0.01, 0.333, 0.01, 0.01]	# (map/train)
    #[1.0, 0.477, 0.154, 0.01, 0.01] # (cos/train)
  end
end
