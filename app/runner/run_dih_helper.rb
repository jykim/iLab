#include ReportHelper
def init_env()
  #Set PATH
  $exp_root = ENV['DH']
  $r_path = ENV['R_PROJECT']
  $indri_path = ENV['INDRI']
  $crfpp_path = ENV['CRFPP']
  $indri_path_dih = '/home/jykim/work/app/indri_dih'
  $indri_path_old = '/home/jykim/work/app/indri25'
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

  #Set Global Vars
  $t_start = Time.now
  if $o[:col_type]
    $col_id = "#{$col}_#{$o[:pid]}_#{$o[:col_type]}"
  else
    $col_id = $col
  end
  $o[:topic_id] = $o[:topic_type] if !$o[:topic_id] && $o[:topic_type]
  $query_prefix = "#{$col_id}_#{$o[:topic_id]}"
  $file_topic = ["topic", $o[:topic_id]].join("_")
  $file_qrel =  ["qrel" , $o[:topic_id]].join("_")

  $qs = {} # performance of query-sets
  $csel_scores = {}

  #Default Retrieval Parameter
  $mu = $o[:mu] || 100
  $lambda = $o[:lambda] || 0.1
  $k1 = $o[:k1] || 1.0
  $method = $exp if !$method
end

def init_collection(col)
  #Choose Collection
  case col
  when 'imdb'
    $index_path = "#$exp_root/imdb/#{$o[:index_path] || 'index_plot'}"
    $i.config_path( :work_path=>$exp_root+'/imdb' ,:index_path=>$index_path )
    $field_prob = [["title", 406], ['%DOC%', 96], ["actors", 21], ["location", 7], ["releasedate", 5], ["year", 2], ["team", 1]]
    $query_lens = [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 9]
    $engine.build_knownitem_topics($file_topic, $file_qrel, $o.dup) if $o[:topic_type] && !File.exist?(to_path($file_topic))
    $ptn_qry_title = ($o[:topic_id] =~ /dbir/)? /\<title\> (.*)/ : /\<title\> (.*) \<\/title\>/
    $fields = ['title','year','releasedate','language','genre', 'country','location','colorinfo','actors','team','plot']
    $offset = case $o[:topic_id]
      when /dbir_train/ : 41
      when /qlm_test/ : 1001
      else 1
      end
    $sparam = get_sparam('jm',0.1)
    #$hlm_weight =  [1.9, 0.3, 0.2, 0.3, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
    $title_field = 'title'
  when 'monster'
    $index_path = "#$exp_root/monster/#{$o[:index_path] || 'index'}"
    $i.config_path( :work_path=>$exp_root+'/monster' ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\> (.*)/
    # $ptn_qry_title = /\<simple\>(.*?)\<\/simple\>/
    $offset = ($o[:topic_id]=='train')? 41 : 1
    if $o[:index_path] == 'index_coarse'
      puts 'Use coarse indexing...'
      $fields = ['resumetitle','summary','desiredjobtitle','education','experience','locations','skills','additionalinfo'] 
    else
      $fields = ['resumetitle','summary','desiredjobtitle','schoolrecord','experiencerecord','location','skill','additionalinfo'] 
    end
    $sparam = get_sparam('jm',0.5)
    $title_field = 'ResumeTitle'
    if $o[:topic_type]
      $query_lens = [5]
      $offset = 1 ; $count = $o[:topic_no] || 50
      #dids = ($o[:pair])? read_qrel($manual_qrel).map_hash{|k,v|[k.to_i,v.keys.first]} : nil
      $engine.build_knownitem_topics($file_topic, $file_qrel, $o.dup.merge(:dids=>dids)) if !File.exist?(to_path($file_topic))
    end
  when 'enron'
    $index_path = "#$exp_root/enron/index_enron"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /= (.*)/
    $offset = 201
    $fields =  ['subject','body','to','from','date']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/enron/doc" , $index_path , :fields=>$fields, :stopword=>false)
    end
    #$field_prob = 
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
    if $o[:topic_type]
      $offset = 1 ; $count = $o[:topic_no] || 50
      $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
    end
  when 'trec'
    $index_path = "#$exp_root/trec/index_lists"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/
    $fields =  ['subject','text','to','sent','name','email']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/trec/raw_doc" , $index_path , :fields=>$fields, :stopword=>false)
    end
    #$field_prob = 
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
    #Topic/Qrel Building
    if $o[:topic_type]
      $offset = 1 ; $count = $o[:topic_no] || 50
      $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
      #$query_lens = [2, 2, 3, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 6, 7, 7, 8, 8, 8, 8, 10]
      #load 'adhoc/trec_field_set.rb'
      #dids = ($o[:pair])? read_qrel($manual_qrel).map_hash{|k,v|[k.to_i,v.keys.first]} : nil
      #$engine.build_knownitem_topics($file_topic, $file_qrel, $o.dup.merge(:dids=>dids)) if !File.exist?(to_path($file_topic))
    else
      case $o[:topic_id]
      when 'disc05'
        $offset, $ptn_qry_title = 1 , /\<query\>(.*)\<\/query\>/
      when 'disc06'
        $offset, $ptn_qry_title = 61, /\<title\> (.*)/
      when 'all'
        $offset, $count = 1, 150
        $file_topic ,$file_qrel = 'ent05.known-item.topics.all', 'ent05.known-item.qrels.all'
      when 'train'
        $offset, $count = 1, 25
        $file_topic ,$file_qrel = 'ent05.known-item.training-topics' , 'ent05.known-item.training-qrels'
      when 'test'
        $offset, $count = 26, 125
        $file_topic ,$file_qrel = 'ent05.known-item-topics', 'ent05.known-item-qrels'
      end
    end
  when 'cs'
    $col_types = ['calendar','webpage','news','file','email'] 
    set_type_info(nil, $o[:col_type])
    $ptn_qry_title = /\<title\>(.*)\<\/title\>/

    #Index Build
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#{CS_COL_PATH}/#{$o[:col_type]}_doc" , $index_path , :fields=>$fields, :stopword=>true)
    end

    #Topic/Qrel Building
    $file_topic = ["topic", $o[:topic_id]].join("_")
    $file_qrel =  ["qrel" , $o[:topic_id]].join("_")
    $engine.build_knownitem_topics($file_topic, $file_qrel) if !File.exist?(to_path($file_topic))
    $offset = 1 ; $count = $o[:topic_no] || 100
    $sparam = get_sparam('jm',0.1)
  when 'pd'
    $col_types = ['msword','ppt','pdf','lists','html']
    set_type_info($o[:pid], $o[:col_type])
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/

    #Index Build
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#{PD_COL_PATH}/#{$o[:pid]}/#{$o[:col_type]}_doc" , $index_path , :fields=>$fields, :stopword=>true)
    end

    #Topic/Qrel Building
    $file_topic = "topic/" + ["topic", $col_id, $o[:topic_id]].join("_")
    $file_qrel =  "qrel/" + ["qrel" , $col_id, $o[:topic_id]].join("_")
    $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
    $offset = 1 ; $count = $o[:topic_no] || 100
    $sparam = get_sparam('jm',0.1)
  #when 'pdm'
  #  #set_type_info($o[:col_type])
  #  $ptn_qry_title = /\<title\> (.*) \<\/title\>/
  #  $query_lens = nil
  #
  #  #Topic/Qrel Building
  #  $file_topic = ["topic", $o[:topic_id]].join("_")
  #  $file_qrel =  ["qrel" , $o[:topic_id]].join("_")
  #  #dids = ($o[:pair])? read_qrel($manual_qrel).map_hash{|k,v|[k.to_i,v.keys.first]} : nil
  #  #$engine.build_knownitem_topics($file_topic, $file_qrel, $o.dup.merge(:dids=>dids)) if !File.exist?(to_path($file_topic))
  #  $offset = 1 ; $count = $o[:topic_no] || 50
  #  $sparam = get_sparam('jm',0.1)
  when 'sf'
    $col_types = ['webpage','music','photo','video'] 
    set_type_info(nil, $o[:col_type])
    $ptn_qry_title = /\<title\>(.*)\<\/title\>/

    #Index Build
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#{SF_COL_PATH}/#{$o[:col_type]}_docs" , $index_path , :fields=>$fields, :stopword=>true)
    end

    #Topic/Qrel Building
    $file_topic = ["topic", $o[:topic_id]].join("_")
    $file_qrel =  ["qrel" , $o[:topic_id]].join("_")
    $engine.build_knownitem_topics($file_topic, $file_qrel, $o) if !File.exist?(to_path($file_topic))
    $offset = 1 ; $count = $o[:topic_no] || 50
    $sparam = get_sparam('jm',0.1)
  end
  # Post-configuration (after $work_path is set)
  $bm25f_path = to_path("#{$query_prefix}_bm25f.in")
end

def get_fields_for(col_type)
  if col_type == 'lists'
    FIELD_EMAIL
  else
    FIELD_ETC
  end
end

def add_prefix(fields, col_type)
  fields.map{|e|"#{col_type}_#{e}"}
end

def set_type_info(pid, col_type)
  if pid
    $index_path = "#$exp_root/pd/index_#{pid}_#{col_type}"
    $i.config_path( :work_path=>File.join($exp_root,$col) ,:index_path=>$index_path )
    $fields = if col_type == 'all'
                $col_types.map{|c|add_prefix(get_fields_for(c), c)}.flatten
              else
                add_prefix(get_fields_for(col_type), col_type)
              end
  else
    case $col
    when 'cs'
      $index_path = "#$exp_root/cs/index_#{col_type}"
      $i.config_path( :work_path=>File.join($exp_root,$col) ,:index_path=>$index_path )
      p CS_FIELDS
      $fields = if col_type == 'all'
                  $col_types.map{|c|add_prefix(CS_FIELD_DEF.concat(CS_FIELDS[c]), c)}.flatten
                else
                  add_prefix(CS_FIELD_DEF.concat(CS_FIELDS[col_type]), col_type)
                end
    when 'sf'
      $index_path = "#$exp_root/sf/index_#{col_type}"
      $i.config_path( :work_path=>File.join($exp_root,$col) ,:index_path=>$index_path )
      $fields = if col_type == 'all'
                  $col_types.map{|c|add_prefix(SF_FIELD_DEF.concat(SF_FIELDS[c]), c)}.flatten
                else
                  add_prefix(SF_FIELD_DEF.concat(SF_FIELDS[col_type]), col_type)
                end      
    end
  end
end

def set_collection_param(col_id)
  case col_id
  when 'trec'
    #['subject','text','to','sent','name','email']
    $hlm_weight = [2.0, 0.652, 0.0, 0.0, 0.0, 0.0]#[0.1,0.1,0.5,0.1,0.3];
    $mflmf_weight = [1.0, 0.292, 1.0, 0.472, 0.0, 0.382]
    $mus = [2.631, 6.386, 18.034, 1.626, 3.947, 6.386]#[3.44418499304202, 4.25724680243181, 13.2742407237162, 20.1626111634632, 3.44418499304202, 0.0]
    $prmd_lambda = 0.7
    $bfs = [0.0, 0.549, 0.0, 0.0, 0.188, 0.0]#[0.0, 0.541019645878629, 0.0, 0.0, 0.291796053982211, 0.0]
    $bm25f_weight = [1.0, 0.292, 0.18, 0.18, 1.0, 0.0]
    $bs = [0.0, 0.138, 0.382, 0.0, 0.382, 0.0]
    $bm25_weight = [0.382, 0.382, 0.0, 0.382, 0.382, 0.0]
  when 'enron'
    $hlm_weight = [2.0, 0.652, 0.0, 0.0, 0.0]
    $mflmf_weight = [1.0, 0.292, 1.0, 0.472, 0.0]
    $mus = [2.631, 6.386, 18.034, 1.626, 3.947]
    $prmd_lambda = 0.7
    $bfs = [0.0, 0.549, 0.0, 0.0, 0.188]
    $bm25f_weight = [1.0, 0.292, 0.18, 0.18, 1.0]
    $bs = [0.0, 0.138, 0.382, 0.0, 0.382]
    $bm25_weight = [0.382, 0.382, 0.0, 0.382, 0.382]
  when 'c0002_lists'
    $mus = [29.993, 0.0, 100.0, 0.0, 100.0, 5.573]#[10,0,15,15,15]#[15, 150, 10, 10, 10]
    $prmd_lambda = 0.9
  when 'c0141_lists'
    $mus = [7.701, 0.0, 5.573, 0.0, 8.204, 18.034] # => [10,0,15,15,15]#[15, 150, 10, 10, 10]
    $hlm_weight = [0.79, 0.79, 0.0, 1.279, 0.0, 0.515]
    $prmd_lambda = 0.9
    $bfs = [1.0, 1.0, 0.0, 0.0, 0.0, 0.0]
    $bm25f_weight = [1.0, 0.18, 0.0, 0.0, 1.0, 0.0]
  when 'c0161_lists'
    $mus = [9.017, 0.0, 100.0, 0.0, 0.0, 3.947]#[59.6747736893892, 36.0679762049892, 20.1626111634632, 1.62612353213767, 100]
    $prmd_lambda = 0.9
    $hlm_weight = [1.0,1.5,0,5,0.5,0.5] #[0.8, 0.2, 0.1, 0.1, 2.0]
    $bfs = [0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
    $bm25f_weight = [1.0, 0.416, 1.0, 0.0, 0.0, 0.0]
  when 'monster'
    $mus = [0.813, 100.0, 0.813, 18.345, 4.257, 6.386, 18.034, 100.0]
    $hlm_weight = [0.43, 0.0, 0.652, 0.515, 0.249, 0.0, 0.292, 0.875]
    $bfs = [0.833, 0.09, 0.854, 0.382, 0.695, 0.562, 0.0, 0.382]
    $bm25f_weight = [1.0, 0.472, 1.0, 0.382, 0.472, 0.562, 0.18, 1.0]
    $prmd_lambda = 0.9
  when 'imdb'
    $bfs= [1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.589, 0.618, 0.133, 0.472, 0.0]
    $bm25f_weight = [1.0, 0.0, 0.618, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.618, 0.0]
    $mus = [0.0, 0.0, 100.0, 0.0, 0.0, 100.0, 47.524, 32.624, 100.0, 61.301, 100.0]
    $hlm_weight = [0.944, 1.348, 0.0, 2.0, 0.0, 0.764, 0.944, 0.292, 0.833, 2.0, 2.0]
    $prmd_lambda = 0.9
  else
    $prmd_lambda = 0.9
  end
end
