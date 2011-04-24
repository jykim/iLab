raise DataError, "query missing" if !$o[:query]
template = $o[:template] || :prm
idx = $o[:idx] || $index_path
sparam = $o[:sparam] || IndriInterface.get_sparam('jm',0.5)
o = $o.merge(:redo=>true, :adhoc_topic=>$o[:query], :index_path=>idx, :template=>template, :smoothing=>sparam)
$i.crt_add_query_set($o[:query].to_fname, o)
info query_file = IO.read(to_path($o[:query].to_fname+".qry"))
info rank_list = $i.rsa.map{ |rs| 
  "== #{rs.name} ==\n\n"+rs.export_docs(:order_by=>'rank', :title_field=>$title_field){|d|d.rank < $topk} 
  }.join("\n")

$i.create_report(binding)
nil

# Getting working set in IMDB
# work_set=[341882,114783].map{|e|'/work1/jykim/prj/dbir/imdb/col/docs_plot_nd/imdb_'+e.to_s+'.xml'}
