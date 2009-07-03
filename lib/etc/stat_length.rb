
module StatLength
  def compare_len_dist(doc_sets)
    s = ""
    doc_sets.each_with_index do |ds1 , i|
      map = (defined? ds1.avg_prec)? '('+ds1.avg_prec.round_at(3).to_s+')' : ''
      s << [ds1.name + map , doc_sets.map_with_index { |ds2 , j| ds1.ldist.to_p.to_a.diff(ds2.ldist.to_p.to_a).round_at(3) if i > j } ].flatten.to_tbl + "\n"

    end
    s
  end
  
  def length_stat_collection()
    if @ldist then return end
    res_file = sprintf('len_%s_all.txt',@name)
    fwrite(res_file , run_length_stat( to_path(res_file) , @name , "ALL" )) if !fcheck(res_file+'.out')
    @ldist = dsvread(res_file+'.out' , :sep_col=>'/').map_hash{|l|[l[2].to_i * @o[:bucket_size], l[4].to_f]}
    puts "collection stat read(#{@ldist.size})"
  end
  
  #Get length points dividing the collection into k equal portions
  def get_length_points( k )
    length_stat_collection
    result = [0] ; unit_ratio = 1 / k.to_f ; dist_cum = @ldist.to_a.to_cum
    dist_cum.each_cons(2){|e| result << e[1][0] if (e[0][1] / unit_ratio).to_i != (e[1][1] / unit_ratio).to_i && e[1][1] < 1.0  }
    result << (dist_cum.last[0]+ @o[:bucket_size])
  end

  # Get length statistics of given document list using file
  def length_stat_docs(doc_list , type)
    file = sprintf('len_%s_%s.txt',@name ,type)
    if !fcheck(file)
      fwrite file+'.tmp' , doc_list.join("\n")
      fwrite file , run_length_stat( to_path(file+'.tmp') , @name , type )
      `unlink #{to_path(file+'.tmp')}`
      `unlink #{to_path(file+'.tmp.err')}` if fcheck(file+'.tmp.err')
      puts file+' created..'
    end
    dsvread(file)
  end

  def length_stat_docset( doc_set , &filter ) #.find_all{|d| (block_given?)? filter.call(b) : true}
    dl = length_stat_docs doc_set.docs.map{|d| d.did} , doc_set.name
    # LESSON Be sure to check validity when working on input data
    dh = dl.map_hash{|e|[e[1] , [e[0].to_i , e[2].to_i]] if e}
    doc_set.docs.each{|d| d.dno , d.size = dh[d.did][0] , dh[d.did][1] if dh[d.did] }
    #doc_set.ldist
  end

  def run_length_stat(file , exp , type = 'ALL')
    cmd = fwrite('cmd_len_stat.log' , "#$indri_path/bin/getlength #$index_path #{file} #@name #{type} #{@o[:bucket_size]}" , :mode=>'a')
    result = `#{cmd}`
    #dbg "[run_length_stat] result = #{result}"
    result
  end

  def partial_rank_stat(doc_set , topk_list)
    topk_list.each do |n|
      length_stat_docs doc_set.docs.find_all{|d| d.rank <= n }.map{|d|d.did} , [doc_set.name,n].join('_')
    end
  end
end



=begin
def get_prob_given_length(exp , type)
  s = dsvread('sum_len_701850.txt',"/")
  h = {} ; dsvread('len_701850_all.txt').each{|e| h[e[2]] = e[3]}
  s.find_all{|e|e[0]==exp and (e[1]==type)}.group_by{|e|e[2]}.map do |k,v|
    exp+'|'+type+'|'+k+'|'+v[0][3]+'|'+(v[0][3].to_f/h[v[0][2]].to_f).to_s
  end.join("\n").write( sprintf('prob_%s_%s.txt',exp ,type) )
end

#Convert Query No. in Resultset
def conv_query_no( file )
  conv_h = {} ; dsvread('0607_mapping.txt').each{|e| conv_h[e[1]] = e[0] }
  File.open( file ) do |f|
    File.open( file+'.out' , 'w' ) do |of|
      while line = f.gets
        a = line.split(' ')
        if new_no = conv_h[a[0]]
          a[0] = new_no
          of.puts a.join(' ')
        end
      end
    end
  end
end

=end
