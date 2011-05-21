
$mprel = $engine.get_mpset_from_flms($queries, $rlflms1)

$qsrel = $i.crt_add_query_set("#{$query_prefix}_PRMSrl", $o.merge(:flms=>$rlflms1, :smoothing=>$sparam_prm))
$maprel = $qsrel.stat2['map'].find_all{|k,v|k != 'all'}.sort_by{|e|e[0].to_i}.map{|e|e[1]}

def get_random_mps(qidx)
  mprel = $engine.get_map_prob($queries[qidx], :flm=>$rlflms1[qidx], :mp_all_fields=>true)  
  #$hlm_weights = [0.5] * $fields.size
  #mpmix = $engine.get_mixture_mpset($queries, [:prior], [1.0])
  probs = $engine.get_probs(mprel)
  probs_r = probs.map{|e|rand()}
  $engine.replace_probs(mprel, probs_r)
end


1.upto(10) do |i|

  $mp_rand = []
  0.upto($queries.size - 1) do |j|
    $mp_rand << get_random_mps(j)
  end
  
  #puts "[mp_random] mp_rand : #{$mp_rand[0].inspect}"

  klds = $engine.get_mpset_klds( $mprel, $mp_rand.map{|e|$engine.marr2hash e} )
  cosines = $engine.get_mpset_cosine( $mprel, $mp_rand.map{|e|$engine.marr2hash e} )
  precs = $engine.get_mpset_prec( $mprel, $mp_rand.map{|e|$engine.marr2hash e} )

  $qs2 = $i.crt_add_query_set("#{$query_prefix}_PRMSrand#{i}", $o.merge(:template=>:tew, :mps=>$mp_rand, :smoothing=>$sparam_prm ))
  
  #p $qsrel.stat2['map']
  #p qs2.stat2['map']
    
  maps = $qs2.stat2['map'].find_all{|k,v|k != 'all'}.sort_by{|e|e[0].to_i}.map_with_index{|e,j|$maprel[j] - e[1]}

  #p maps, klds, cosines, precs
  
  puts [klds.pcc(maps), cosines.pcc(maps), precs.pcc(maps), $qs2.stat2['map']['all'], $maprel.stat2['map']['all']].join("\t")
end

