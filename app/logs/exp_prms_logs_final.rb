# TREC

$o = {:topic_id=>'test', :verbose=>:mp) }; $method='final'; $col='trec'; $exp='perf'; $remark='0522'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test',:redo=>true }; $method=nil; $col='trec'; $exp='mp_random'; $remark='0521'; eval IO.read('run_prms.rb')

# Monster

$o = {:topic_id=>'cv2', :verbose=>:mp, :mp_sparam=>0.1,:mp_types=>[:cug, :rug, :cbg, :prior, :rbg ]}; $method='final'; $col='monster'; $exp='perf'; $remark='0516_mpsmt'; eval IO.read('run_prms.rb')


# Enron2

['cosine','map'].each do |opt_for|
  $o={:mode=>:mix_weights, :redo=>true, :opt_for=>opt_for, :topic_id=>'train'}; $col='enron2' ;$exp='optimize_mix'; $method='golden'; $remark='0515'; eval IO.read('run_prms.rb')
end

$o = {:topic_id=>'test', :verbose=>:mp,:redo=>true}; $method='final'; $col='enron2'; $exp='perf'; $remark='0515'; eval IO.read('run_prms.rb')

# IMDB

['cosine','map'].each do |opt_for|
  $o={:mode=>:mix_weights, :redo=>true, :opt_for=>opt_for, :topic_id=>'cv2'}; $col='monster' ;$exp='optimize_mix'; $method='golden'; $remark='0514'; eval IO.read('run_prms.rb')
end

$o = {:topic_id=>'dcv2', :verbose=>:mp}; $method='final'; $col='imdb'; $exp='perf'; $remark='0514'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights, :redo=>true, :opt_for=>'cosine', :topic_id=>'cv1'}; $col='monster' ;$exp='optimize_mix'; $method='golden'; $remark='0514'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'cv1', :verbose=>:mp}; $method='final'; $col='imdb'; $exp='perf'; $remark='0515'; eval IO.read('run_prms.rb')

# Feature Ablation

[[:cug, :cbg, :prior ], [:rug, :rbg , :prior], [:cug, :cbg, :rug, :rbg], [:cug, :rug , :prior]].each do |mp_types|
  $o={:mode=>:mix_weights, :redo=>true, :opt_for=>'map', :topic_id=>'train', :mp_types=>mp_types}; $col='trec' ;$exp='optimize_mix'; $method='golden'; $remark='0514_ablation'; eval IO.read('run_prms.rb')
end

[[:cug, :cbg, :prior ], [:rug, :rbg , :prior], [:cug, :cbg, :rug, :rbg], [:cug, :rug , :prior]].each do |mp_types|
  $o={:topic_id=>'test', :mp_types=>mp_types}; $col='trec' ;$exp='perf'; $method='final'; $remark='0515_ablation'; eval IO.read('run_prms.rb')
end

# 
