

\rm -r index_lists gindex_lists query/*gPRM-S* in/FREQ_index_lists.in


#== Building a Synthetic Collection

$o = {:mp_all_fields=>true,:redo=>true,:verbose=>true,:topic_type=>'F_RN_RN',:topic_id=>'0401', :topic_no=>50}; $method='engines_mflm'; $col='trec'; $exp='perf';$remark='0401'; eval IO.read('run_prms.rb')

$o = {:redo=>true,:verbose=>true,:topic_type=>'F_RN_RN',:topic_id=>'0401',:col_id=>'col1', :topic_no=>50}; $method='engines_mflm'; $col='syn'; $exp='perf';$remark='0401'; eval IO.read('run_prms.rb')

#== Oracle MP Estimation

# Syn collection
$o = {:redo=>true,:verbose=>true,:mix_ratio=>0.2,:topic_type=>'F_RN_RN',:topic_id=>'0404',:col_id=>'m02', :topic_no=>50}; $method='prms_ora'; $col='syn'; $exp='perf';$remark='0404'; eval IO.read('run_prms.rb')

# TREC collection
$o = {:redo=>true, :verbose=>:mp, :topic_type=>'F_RN_RN', :topic_id=>'0404a', :topic_no=>100}; $method='prms_ora'; $col='trec'; $exp='perf'; $remark='0404'; eval IO.read('run_prms.rb')

