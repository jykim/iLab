load 'app/ilab.rb'
load 'app/adhoc/twir_feature.rb'
$docs = index_path('html')
process_input('TcUrl.list.resolve')

#dt = IO.read('TcUrl.list.resolve.10').split("\n").map{|e|e.split("\t")}
$o = {:verbose=>true, :topic_id=>'test'}; $method='twir_smt'; $col='twir'; $exp='perf'; $remark='0121'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test'}; $method='twir_smt'; $col='twir'; $exp='perf'; $remark='0119_new'; eval IO.read('run_prms.rb')

$o = {:verbose=>true, :topic_id=>'test',:topk=>50}; $method='twir_smt'; $col='twir'; $exp='document'; $remark='0120'; eval IO.read('run_prms.rb')
