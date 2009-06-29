#General Qrel Stub
if !File.exist?(to_path($file_qrel))
  $i.fwrite $file_qrel , $i.rsa.map{|ds|ds.docs.find_all{|d|d.rank<=$topk}.
      map{|d|[d.qid,0,d.did,'-1'].join(' ')}}.flatten.uniq.sort_by{|e|a = e.split(" ") ; [a[0].to_i,a[2]]}.join("\n")
end
if $o[:old_qrel]
  info 'Updating Qrel...'
  update_qrel(to_path($o[:old_qrel]), to_path($file_qrel)) 
end
$i.add_relevant_set($file_qrel)
str = $i.rl.export_docs({:title_field=>$title_field, :order_by=>'qid'}){|e|true}
$i.create_report(binding)
nil
