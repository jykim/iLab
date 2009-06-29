DEFAULT_ENGINE_TYPE = :indri
load 'ilab.rb'

$t_start = Time.now
$o = $o.merge({:env=>'cval'})
$root_path = File.join(ENV['PJ'] , $root)

$i = ILab.new($col , get_opt_ilab($o))
$i.config_path( :work_path=>File.join($root_path,$col) ,:index_path=>nil )
$r = {}

begin#exception handling

  #Training Phase
  $tg = ThreadGroup.new ; $r[:train] = {}
  0.upto($o[:cval_no]-1) do |i|
    thr_cv = Thread.new(i) do |i|
      tmp_r = run_ilab(get_expid_from_env($o.merge({:exp=>$exp, :cval_id=>i})))
      Thread.critical = true
        $r[:train][i] = tmp_r
      Thread.critical = false
    end#thread
    $tg.add thr_cv
  end
  $tg.list.each_with_index do |thr , i|
    thr.join
    puts "[run_cval.rb] Training #{i}th fold finished"
  end

  #Test Phase
  $tg2 = ThreadGroup.new ; $r[:test] = {}
  0.upto($o[:cval_no]-1) do |i|
    raise ExternalError , "No param_opt from #{i}th fold" if !$r[:train][i][:param_opt]
    thr_cv = Thread.new(i) do |i|
      tmp_r = run_ilab(get_expid_from_env($o.merge({:exp=>'perf', :query_wise=>true, :method=>'opt_test', :cval_id=>i})), $r[:train][i][:param_opt])
      #tmp_r2 = run_ilab(get_expid_from_env($o.merge({:exp=>'length', :method=>'opt_test', :cval_id=>i})), $r[:train][i][:param_opt])
      Thread.critical = true
        $r[:test][i] = tmp_r
      Thread.critical = false
    end#thread
    $tg2.add thr_cv
  end
  $tg2.list.each_with_index do |thr , i|
    thr.join
    puts "[run_cval.rb] Test #{i}th fold finished"
  end

rescue ExternalError
  puts "External Program Failed!"
end

#Run Experiment & Generate Report
eval IO.read(to_path("exp_#{$exp}.rb"))
$i.create_report_index

info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
