['0112a','0112b','0112c'].each{|topic_id| ['c0161'].each{|pid|
  begin
    $o={:verbose=>true,:pid=>pid,:col_type=>'all',:query_len=>2,:topic_no=>50,:topic_id=>topic_id,:topic_type=>'D_TF'}; $method='meta_with_best'; 
    $col='pd'; $exp='perf'; $remark='0111_with_best'; eval IO.read('run_dih.rb')
  rescue Exception => e
    puts e
  end
  }}

['calendar','webpage','news','file','email'].each{|e|`scp data/docs/doc_#{e}_* $SYC/prj/dih/cs/raw/#{e}_doc`}

$o={:verbose=>true,:col_type=>'all',:query_len=>2,:topic_no=>50,:topic_id=>'test',:topic_type=>'D_TF'}; $method='meta_with_best'; $col='cs'; $exp='perf'; $remark='0117'; eval IO.read('run_dih.rb')

\rm raw/webpage_doc/doc_webpage_4151_production.txt raw/webpage_doc/doc_webpage_4384_production.txt 