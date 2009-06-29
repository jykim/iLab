# < Distributed Processing >
# ex) $o={:k=>24}; $args=['http://portal.acm.org/citation.cfm?id=']; $in='clicks.txt'; $job='target_for_site'; eval IO.read('qlm.rb')

load 'ilab.rb'
WORK_PATH = "/work1/jykim/data/queryLogs"
$in = File.join(WORK_PATH, $in)
#Process Input Argument
$o = {} if !defined?($o)
$args = [] if !defined?($args)

a_nodes = get_anodes()

$o[:k] = a_nodes.size if !$o[:k]

#Divide the input file
in_files = run_split($in, File.basename($in)+".part", :k=>($o[:k]-1))
assert_equal($o[:k], in_files.size, "#{$o[:k]} input files")

#Submit jobs
a_nodes=a_nodes[0..($o[:k]-1)]
cmds = [] ; a_nodes.each_with_index{|e,i|cmds << "#{RUBY_CMD} #$ilab_root/ilab/adhoc/qlm_jobs.rb #{in_files[i]} #$job #{$args.map{|e|"\"#{e}\""}.join(" ")}"}
run_cluster(a_nodes.map{|e|e[0]}, cmds, :timeout=>600)

