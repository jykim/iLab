module RInterface
  #Significance Test using R
  def sig_test(qs1, qs2, o={})
    s  = "source ('#{to_path('sig_test.R')}')\n"
    s += "x <- read.pair('#{to_path(qs1+'.eval')}', '#{to_path(qs2+'.eval')}' )\n"
    s += "p <- hyp.test(x, 'map', test=t.test, paired=T)\n"
    s += "p\n"
    file_name = "sig_test_#{qs1}-#{qs2}"
    fwrite("#{file_name}.in", s)
    run_R(file_name)
  end
  
  #Kolmogorov-Smirnov Goodness-of-the-fit Test
  def ks_test(file_pattern, o={})
    s  = "source ('#{to_path('sig_test.R')}')\n"
    s += "x <- read.eval(#{file_pattern})\n"
    s += "p <- hyp.test(x, 'map', test=ks.test)\n"
    s += "p\n"
    file_name = "ks_test_#{file_pattern.scan(/\w/)}"
    fwrite("#{file_name}.in", s)
    run_R(file_name)
  end
  
  #Logistic Regression using R
  def log_reg(qs1, qs2, tbl)
    file_name = "lgr_#{qs1}-#{qs2}"
    dsvwrite("#{file_name}_tbl.in", tbl, :sep_col=>',')
    s  = "source ('#{to_path('log_reg.R')}')\n"
    s += "x <- log_reg_qs(#{qs1}, #{qs2}, '#{to_path("#{file_name}_tbl.in")}')\n"
    s += "summary(x)\n"
    fwrite("#{file_name}.in", s)
    run_R(file_name)
  end
  
  def check_R()
    File.exist?("#{$r_path}")
  end
  
  def run_R(file_name)
    cmd = fwrite('cmd_R.log' , "#{$r_path} --no-save < #{to_path(file_name+'.in')}" , :mode=>'a')
    result = fwrite(file_name+'_r.log'   , `#{cmd}`)
    [file_name+'_r.log', result]
  end
end
