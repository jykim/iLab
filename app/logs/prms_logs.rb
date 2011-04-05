

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
$o = {:redo=>true, :verbose=>:mp, :topic_id=>'test'}; $method='prms_res'; $col='trec'; $exp='perf'; $remark='0405'; eval IO.read('run_prms.rb')


#== Mixture Model for MP Estimate

$o={:mode=>:hlm_weights,:topic_id=>'0404'}; $col='trec' ;$exp='optimize_prm'; $method='golden'; eval IO.read('run_prms.rb')

