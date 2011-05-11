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

