# Parameter Sweep

$o = {:redo=>true,:topic_id=>'train', :verbose=>true}; $method='param_smt'; $col='trec'; $exp='perf'; $remark='0505_ifix'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'test', :verbose=>true}; $method='param_smt'; $col='enron'; $exp='perf'; $remark='0510'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'test', :verbose=>true}; $method='param_smt'; $col='monster'; $exp='perf'; $remark='0507'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:topic_id=>'dtest', :verbose=>true}; $method='param_smt'; $col='imdb'; $exp='perf'; $remark='0510'; eval IO.read('run_prms.rb')

# Weight Training

$o={:mode=>:hlm_weights,:topic_id=>'train'}; $col='enron' ;$exp='optimize_prm'; $method='golden'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:opt_for=>'map',:topic_id=>'test', :sparam=>get_sparam('jm',0.1)}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; $remark='0506'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights, :opt_for=>'map', :topic_id=>'dtrain'}; $col='imdb' ;$exp='optimize_rpm'; $method='golden'; $remark='0507'; eval IO.read('run_prms.rb')

# Debugging

$o = {:topic_id=>'train', :verbose=>:mp,:redo=>true }; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0511_debug'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtrain', :verbose=>:mp,:redo=>true }; $method='prms_mix'; $col='imdb'; $exp='perf'; $remark='0511_debug'; eval IO.read('run_prms.rb')


# Evaluate Oracle

$o = {:redo=>true,:topic_id=>'test', :sparam=>get_sparam('jm',0.1), :verbose=>true}; $method='mp_oracle'; $col='trec'; $exp='perf'; $remark='0507_jm'; eval IO.read('run_prms.rb')

# Get Results

# TREC

$o = {:topic_id=>'test', :verbose=>:mp, :sparam=>get_sparam('jm',0.1) }; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0509_optmap'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:opt_for=>'map',:redo=>true, :topic_id=>'train', :sparam=>get_sparam('jm',0.1)}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; $remark='0506_jm'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp, :range=>[117,138,36,71,150,60,72,137,124,45,109,129,44,88]}; $method='prms_mix'; $col='trec'; $exp='document'; $remark='0509'; eval IO.read('run_prms.rb')

$engine.debug_prm_query(36, :prms, ['lists-017-11143340','lists-017-14056498','lists-017-11289193'])

#$o = {:topic_id=>'test', :verbose=>:mp, :sparam=>get_sparam('jm',0.1) }; $method='param_prmd'; $col='trec'; $exp='perf'; $remark='0509_optmap'; eval IO.read('run_prms.rb')

# Enron


$o = {:topic_id=>'test', :verbose=>:mp, :range=>[107,127,53,19,115,9,143,102]}; $method='prms_mix'; $col='enron'; $exp='document'; $remark='0509'; eval IO.read('run_prms.rb')

$engine.debug_prm_query(53, :prms, ['688347.1075840813520.JavaMail.evans@thyme','8815793.1075840813281.JavaMail.evans@thyme'], :sparam => 0.1)

$engine.debug_prm_query(107, :prms,['17318615.1075845678762.JavaMail.evans@thyme','21756290.1075845678833.JavaMail.evans@thyme'])

$o = {:topic_id=>'test', :verbose=>:mp}; $method='prms_mix'; $col='enron'; $exp='perf'; $remark='0510'; eval IO.read('run_prms.rb')

# IMDB

$o={:mode=>:mix_weights,:opt_for=>'map',:redo=>true, :topic_id=>'dtest'}; $col='imdb' ;$exp='optimize_rpm'; $method='golden'; $remark='0510'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp}; $method='pmix_var'; $col='monster'; $exp='perf'; $remark='0510'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtest', :verbose=>:mp}; $method='final'; $col='imdb'; $exp='perf'; $remark='0510'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'dtest', :verbose=>:mp, :range=>[6,33,39]}; $method='final'; $col='imdb'; $exp='document'; $remark='0510_local'; eval IO.read('run_prms.rb')

$o={};$engine.debug_prm_query(6, :prms, ['imdb_855.xml', 'imdb_265690.xml', ], :sparam=>0.1)

$o = {:topic_id=>'dtest', :verbose=>:mp, :range=>[3,28,14,20,31,9,1,22]}; $method='prms_mix'; $col='imdb'; $exp='document'; $remark='0509'; eval IO.read('run_prms.rb')

$o={};$engine.debug_prm_query(3, :prms, ['imdb_196520.xml', 'imdb_283601.xml', ], :sparam=>250)
$o={};$engine.debug_prm_query(4, :prms, ['imdb_32838.xml', 'imdb_79791.xml', ], :sparam=>250)
$o={};$engine.debug_prm_query(25, :prms, ['imdb_28636.xml', 'imdb_295862.xml', ], :sparam=>250)
$o={};$engine.debug_prm_query(27, :prms, ['imdb_42307.xml', 'imdb_341412.xml', ], :sparam=>250)

$o = {:topic_id=>'qtest', :verbose=>:mp, :redo=>true}; $method='prms_mix'; $col='imdb'; $exp='perf'; $remark='0508'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'qtest', :verbose=>:mp, :range=>[509,256,643,369,240,508,538,957, 142, 143,125]}; $method='prms_mix'; $col='imdb'; $exp='document'; $remark='0509'; eval IO.read('run_prms.rb')


# Monster

$o = {:topic_id=>'test', :verbose=>:mp, :redo=>true}; $method='prms_mix'; $col='monster'; $exp='perf'; $remark='0511'; eval IO.read('run_prms.rb')


