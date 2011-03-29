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

  #Default Retrieval Parameter
  $mu = $o[:mu] || 100
  $lambda = $o[:lambda] || 0.1
  $k1 = $o[:k1] || 1.0
  $method = $exp if !$method
end

def init_collection(col)
  #Choose Collection
  case col
  when 'enron'
    $index_path = "#$exp_root/enron/index_enron"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    puts "work_path : #$work_path"
    $ptn_qry_title = /= (.*)/
    $offset = 201
    $fields =  ['subject','body','to','from','date']
    #$field_prob = 
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
  when 'trec'
    $index_path = "#$exp_root/trec/index_lists"
    $gindex_path = "#$exp_root/trec/gindex_lists"
    $i.config_path( :work_path=>File.join($exp_root,col) ,:index_path=>$index_path )
    $ptn_qry_title = /\<title\> (.*) \<\/title\>/
    $fields =  ['subject','text','to','sent','name','email']
    if !File.exist?($index_path)
      $engine.build_index($col_id , "#$exp_root/trec/raw_doc" , $index_path , :fields=>$fields, :stemming=>:none, :stopword=>false)
    end
    if !File.exist?($gindex_path)
      $gengine.build_index($col_id , "#$exp_root/trec/gdoc/w3c-lists_small.trecweb" , $gindex_path , :fields=>$fields, :stopword=>false)
    end
    #$field_prob = 
    $sparam = get_sparam('jm',0.1)
    $title_field = "SUBJECT"
    #Topic/Qrel Building
    if $o[:topic_type]
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
  end
end