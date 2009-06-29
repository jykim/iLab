DEFAULT_ENGINE_TYPE = :indri
load 'ilab.rb'

#Set Arguments
$col = 'trec3' if !defined?($col)
$exp = 'set_optimize' if !defined?($exp)
$method = 'range_opt' if !defined?($method)

$t_start = Time.now
$o = {:set_no=>3} if !defined?($o)
$o[:set_no] = 3 if !$o[:set_no]
$o = $o.merge({:env=>'set'})

$i = ILab.new($col , get_opt_ilab($o))
$i.config_path( :work_path=>ENV['IH']+'/'+$col ,:index_path=>nil )
$r = {}

begin#exception handling

  #Training Phase
  $tg = ThreadGroup.new
  0.upto($o[:set_no]-1) do |i|
    #thr_cv = Thread.new(i) do |i|
      tmp_r = run_ilab(get_expid_from_env($o.merge({:exp=>'perf', :set_id=>i})))
    #end#thread
    #$tg.add thr_cv
  end
  $tg.list.each_with_index do |thr , i|
    thr.join
    puts "[run_set.rb] #{i}th fold finished"
  end

rescue ExternalError
  puts "External Program Failed!"
end

#Run Experiment & Generate Report
eval IO.read(to_path("exp_#{$exp}.rb"))
$i.create_report_index

info("For #{get_expid_from_env()} experiment, #{Time.now - $t_start} second elapsed...")
