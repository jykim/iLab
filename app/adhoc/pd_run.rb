['0111c'].each{|topic_id| ['c0161'].each{
  |pid|$o={:verbose=>true,:pid=>pid,:col_type=>'all',:query_len=>2,:topic_id=>topic_id,:topic_type=>'D_TF'}; $method='meta_with_best'; 
  $col='pd'; $exp='perf'; $remark='0110'; eval IO.read('run_dih.rb')}}
