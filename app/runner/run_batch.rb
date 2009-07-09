# Batch execution of ILab instances
load 'ilab.rb'

$root_path = File.join(ENV['PJ'] , $root)
$t_start = Time.now
$o = $o.merge({:env=>'batch'}) if !$o[:env]

$i = ILab.new($col , get_opt_ilab($o))
$i.config_path( :work_path=>File.join($root_path,$col) ,:index_path=>nil )
$r = []

begin#exception handling
  topic_priors = ['length','pagerank']
  topic_types = $o[:topic_types] || TOPIC_TYPES
  col_types = $o[:col_types] || COL_TYPES
  pids = $o[:pids] || PIDS #
  anodes = get_anodes()
  query_method = $o[:query_method] || 'simple'
  case $method
  # < Konwn-iterm Topic Generation >
  # $o={}; $method='ki_topics'; $exp='perf'; $col='pd'; $root='dih'; $remark='0527a'; eval IO.read('run_batch.rb')
  when 'ki_topics'
    case $col
    when 'pd'
      pids.each do |pid|
        col_types.each_with_thread do |col_type, i|
          topic_types = case col_type
                        when 'lists'
                          ['F_subject_TF','F_text_TF']
                        else
                          ['F_title_TF','F_text_TF']
                        end
          topic_types.each do |topic_type|
            $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>$exp,:method=>query_method,
              :remark=>"#{pid}_#{col_type}_#$remark",:pid=>pid,:col_type=>col_type,
              :topic_id=>"#{topic_type}_#$remark",:topic_type=>topic_type,:topic_no=>100)), nil, 
              :remote=>true, :nid=>anodes[i%anodes.size][0])
          end
        end
      end
    else
      topic_types.each_with_thread do |topic_type, i|
        $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>$exp,:method=>query_method,
          :topic_id=>"#{topic_type}_#$remark",:topic_type=>topic_type,:topic_no=>500)), nil, 
          :remote=>true, :nid=>anodes[i%anodes.size][0])
      end
    end
  when 'meta'
    ['0318d'].each do |topic_id|
      ["cql","nmp"].each do |col_score|
        ["none","minmax"].each do |norm|
          topic_types.each_with_thread do |topic_type, i|
            $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>$exp,
            :method=>query_method,:topic_id=>"#{topic_type}_#{topic_id}",
            :col_score=>col_score,:norm=>norm)), nil, 
              :remote=>true, :nid=>anodes[i%anodes.size][0])
          end
        end
      end
    end
  when 'multi_col'
    topic_type = "F_RN_RN"
    PIDS.each do |pid|
      ['0708a','0708b','0708c'].each_with_thread do |topic_id,i|
        $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>$exp,
          :method=>query_method,:topic_id=>"#{topic_type}_#{topic_id}",:topic_type=>topic_type)), nil, 
          :remote=>true, :nid=>anodes[i%anodes.size][0])
      end
    end
  when 'manual_qrel'
    ['c0161'].each do |pid|
      ['html','lists','pdf','msword','ppt'].each_with_thread do |col_type,i|
        $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>'qrel',:pid=>pid,:col_type=>col_type,
        :topic_id=>"F_RN_IDF_#$remark",:topic_type=>'F_RN_IDF')), nil, 
        :remote=>true, :nid=>anodes[i%anodes.size][0])
      end
    end
  when 'cval_crf'
    (0...$o[:cval_no]).to_a.each_with_thread do |e, i|
      #info "starting #{i} th fold"
      $r << run_ilab($root, get_expid_from_env($o.merge(:exp=>$exp,:method=>'cval_crf', :cval_id=>i)), nil, 
        :remote=>true, :nid=>anodes[i%anodes.size][0])
      info "Result : #{$r.inspect}"
    end
  end
rescue ExternalError
  puts "External Program Failed! " + $!.inspect
end

#Run Experiment & Generate Report
#eval IO.read(to_path("exp_#{$exp}.rb"))
#$i.create_report_index

info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
