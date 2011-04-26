

#== Useful Commands

\rm -r index_lists gindex_lists in/FREQ_index_lists.in



#== Indri Apps Deployment

scp kstem.cpp calc_mp.cpp $SYH/work/dev/indri-5.0
cp Makefile.app Makefile.kstem
cp Makefile.app Makefile.calc_mp
make -f Makefile.kstem
make -f Makefile.calc_mp
cp kstem calc_mp $INDRI/bin

# Finding whether an Indri index is stemmed
$cf = $engine.get_col_freq ;puts $cf['document']['agents'] ,$cf['document']['agent']

# Testing get_res_flms

$engine.get_res_flm $i.qsa[0].qrys[0].rs.docs

#== Building a Synthetic Collection

$o = {:mp_all_fields=>true,:redo=>true,:verbose=>true,:topic_type=>'F_RN_RN',:topic_id=>'0401', :topic_no=>50}; $method='engines_mflm'; $col='trec'; $exp='perf';$remark='0401'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:verbose=>true,:topic_type=>'F_RN_RN',:topic_id=>'0401',:col_id=>'col1', :topic_no=>50}; $method='engines_mflm'; $col='syn'; $exp='perf';$remark='0401'; eval IO.read('run_prms.rb')

#== Oracle MP Estimation

# Syn collection
$o = {:redo=>true,:verbose=>true,:mix_ratio=>0.2,:topic_type=>'F_RN_RN',:topic_id=>'0404',:col_id=>'m02', :topic_no=>50}; $method='prms_ora'; $col='syn'; $exp='perf';$remark='0404'; eval IO.read('run_prms.rb')

# TREC syn
$o = {:redo=>true, :verbose=>:mp, :topic_type=>'F_RN_RN', :topic_id=>'0404b', :topic_no=>100}; $method='prms'; $col='trec'; $exp='perf'; $remark='0404'; eval IO.read('run_prms.rb')

# TREC syn / PRF-based MP estimation
$o = {:topk=>5, :verbose=>:mp, :topic_type=>'F_RN_RN', :topic_id=>'0405', :topic_no=>100}; $method='prms_res'; $col='trec'; $exp='perf'; $remark='0405'; eval IO.read('run_prms.rb')

# TREC col / test topic
$o = {:topic_id=>'test', :verbose=>:mp}; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0424_weightrain'; eval IO.read('run_prms.rb')

$o = {:redo=>true, :verbose=>:mp, :topic_id=>'test'}; $method='prms'; $col='trec'; $exp='perf'; $remark='0424'; eval IO.read('run_prms.rb')


# Enron col / all topics
$o = {:verbose=>true, :topic_id=>'all'}; $method='prms'; $col='enron'; $exp='perf'; $remark='0406'; eval IO.read('run_prms.rb')


#== Mixture Model for MP Estimate

['prms_mix','prms_ora'].each do |method|
  $o = {:verbose=>:mp, :topic_id=>'test'}; $method=method; $col='trec'; $exp='perf'; $remark='0406'; eval IO.read('run_prms.rb')
end

#== Query Generation

$o = {:verbose=>nil, :topic_id=>'test', :new_topic_id=>'MKV0415', :no_cand=>3, :max_length=>2}; $method=nil; $col='trec'; $exp='gen_query'; $remark='0415'; eval IO.read('run_prms.rb')

$o = {:redo=>true, :verbose=>:mp, :topic_type=>'MKV', :topic_id=>'MKV0415'}; $method='prmsmix'; $col='trec'; $exp='perf'; $remark='0415'; eval IO.read('run_prms.rb')



#== Optimal Parameter finding for Mixture MP model (4/24)
$o={:mode=>:hlm_weights,:topic_id=>'train'}; $col='trec' ;$exp='optimize_prm'; $method='golden'; eval IO.read('run_prms.rb')

$o={:mode=>:mix_weights,:topic_id=>'train'}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; eval IO.read('run_prms.rb')

$o={:verbose=>true,:mode=>:mix_weights,:opt_for=>'kld',:topic_id=>'train'}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; eval IO.read('run_prms.rb')

#== Retrieval Experiments using Generated Queries (4/25)

$o = {:verbose=>true, :topic_id=>'test', :new_topic_id=>'MKV0425', :no_cand=>10}; $method=nil; $col='trec'; $exp='gen_query'; $remark='0425_nostopwords'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'MKV0425', :verbose=>:mp}; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0425_gen_train'; eval IO.read('run_prms.rb')


#== Adding Features to Mixture MP Models (4/25)

$o={:mode=>:mix_weights,:opt_for=>'map',:topic_id=>'train'}; $col='trec' ;$exp='optimize_rpm'; $method='golden'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'test', :verbose=>:mp}; $method='prms_mix'; $col='trec'; $exp='perf'; $remark='0425_weightrain'; eval IO.read('run_prms.rb')

#== Getting Baseline Results for Enron & IMDB (4/26)

$o = {:topic_id=>'train', :verbose=>true}; $method='param_jm'; $col='enron'; $exp='perf'; $remark='0426_param'; eval IO.read('run_prms.rb')

$o = {:topic_id=>'train', :verbose=>true}; $method='param_dir'; $col='imdb'; $exp='perf'; $remark='0426_param'; eval IO.read('run_prms.rb')

