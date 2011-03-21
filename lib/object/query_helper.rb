module QueryHelper  
  def run_trec_eval(qrel_file , result_file)
    cmd = fwrite('cmd_trec_eval.log' , "#{$trec_eval_path}/bin/trec_eval -q #{to_path(qrel_file)} #{to_path(result_file)} " , :mode=>'a')
    fwrite(@name+'.eval'   , `#{cmd}`)
    #puts "[run_trec_eval] stat for '#{result_file}' calculated"
  end
end
