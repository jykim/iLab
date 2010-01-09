['0109d','0109e','0109f'].each{|topic_id| ['c0161'].each{
  |pid|$o={:verbose=>true,:pid=>pid,:col_type=>'all',:topic_id=>topic_id,:topic_type=>'F_RN_RN'}; $method='meta_with_best'; 
  $col='pd'; $exp='perf'; $remark='0106'; eval IO.read('run_dih.rb')}}

