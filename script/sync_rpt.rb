prj  = ARGV[0]
col  = ARGV[1] || ['monster', 'imdb']# || ['ttb','w10g','trec3'] #','trecblog', ttbs','ttbm',
type = ARGV[2] || ['rpt', 'doc', 'log', 'in']
col.each do |e|
  type.each do |e2|
    `rsync -aq #{ENV['SYC']}/prj/#{prj}/#{e}/#{e2} #{ENV['PJ']}/#{prj}/#{e}`
  end
end
