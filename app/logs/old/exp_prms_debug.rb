= Merging MP =


irb(main):009:0> p p1 = $engine.get_doc_field_lm('imdb_225145.xml')[1]['title']
{"the"=>0.333333333333333, "mummy"=>0.333333333333333, "return"=>0.333333333333333}
=> 
irb(main):010:0> p p2 = $engine.get_doc_field_lm('imdb_225165.xml')[1]['title']
{"the"=>0.5, "mummy"=>0.5}
=> 
irb(main):011:0> p1.sum_prob p2
=> the0.833333333333333mummy0.833333333333333return0.333333333333333
irb(main):012:0> p (p1.sum_prob p2)
{"the"=>0.833333333333333, "mummy"=>0.833333333333333, "return"=>0.333333333333333}
=> 


$engine.get_mpset_klds( $mprel, $mpmix2.map{|e|$engine.marr2hash e} ).avg
$engine.get_mpset_klds( $mprel, $mpmix3.map{|e|$engine.marr2hash e} ).avg
$engine.get_mpset_cosine( $mprel, $mpmix2.map{|e|$engine.marr2hash e} ).avg
$engine.get_mpset_cosine( $mprel, $mpmix3.map{|e|$engine.marr2hash e} ).avg
$engine.get_mpset_prec( $mprel, $mpmix2.map{|e|$engine.marr2hash e} ).avg
$engine.get_mpset_prec( $mprel, $mpmix3.map{|e|$engine.marr2hash e} ).avg

$mpmix_ora = $engine.get_mixture_mpset($queries, [:ora2], [1])
qsora = $i.crt_add_query_set("#{$query_prefix}_PRMSora", o.merge(:template=>:tew, :mps=>$mpmix_ora, :smoothing=>$sparam_prm ))
qsora.stat['all']['map']
