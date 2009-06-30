plot = []
$i.qsa.group_by{|qs| qs[:minDocLen] }.each do |k,v| 
  plot << {:label=>'Len_'+k.to_s , :data=>v.map{|qs| [qs[:mu] , qs.stat['all']['map']] }}
end

$i.create_report(binding)
nil

