require 'lib/interface/gnuplot'

module GnuplotHandler
  #Get (One/Multiple) Line Plot
  # - Table-driven
  #  - {:data=>[[x0,y1-0,y2-0,..],...] , :label=>['label_x','label_y1','label_y2'] }
  # - Plot-driven
  #  - [{:data => [[x0,y0],[x1,y1]] , :label => 'plot1'} , {:data => [[x0,y0],[x1,y1]] , :label => 'plot2'}]
  def get_plot(title , xlabel , ylabel , o = {} )
    file_name = to_path( (o[:filename] || get_plot_filename(title , o)) )
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.title title ; plot.xlabel xlabel ; plot.ylabel ylabel
        plot.output file_name
        plot.terminal o[:terminal] || 'png'
                
        plot.xrange o[:xrange] if o[:xrange]
        plot.yrange o[:yrange] if o[:yrange]
        plot.logscale o[:logscale] if o[:logscale]
        plot.size o[:size] if o[:size]
        #plot.multiplot
        
        plot_str = []
        if o[:data] && o[:label] #Table-driven 
          plot_str << '# '+o[:label].join("\t")
          o[:data].each{|l|plot_str << l.join("\t")}
          o[:data][0].each_with_index do |d,i|
            if i == 0 then next end
            plot.data << Gnuplot::DataSet.new( [o[:data].map{|e|e[0]}, o[:data].map{|e|e[i]}] ) do |ds|
              ds.with = (o[:with]) ? o[:with][i-1] : "linespoints"
              ds.title = o[:label][i-1]
            end
            plot.to_gplot(gp)
          end
        elsif o[:plot] #Plot-driven 
          #puts 'Plot : ' + o[:plot].inspect
          o[:plot].each_with_index do |p,i|
            p[:data] = p[:data].to_a.sort_by{|e|e[0]} if p[:data].class == Hash
            p[:data] = p[:data].map_with_index{|e,i| [i , e] } if p[:data].class == Array && p[:data][0].class != Array
            #p[:data] = p[:data].find_all{|e| e }
            plot_str << '# '+p[:label]
            p[:data].each{|l|plot_str << l.join("\t")}

            plot.data << Gnuplot::DataSet.new( [p[:data].map{|e|e[0]} , p[:data].map{|e|e[1]} ] ) do |ds|
              ds.with = (p[:with]) ? p[:with] : "linespoints"
              ds.title = p[:label] || ('plot_'+i.to_s)
            end
            plot.to_gplot(gp)
          end
        else
          puts 'Not Enough Data!'
        end
        fwrite "#{get_plot_filename(title , o)}.plotdata" , plot_str.join("\n") if plot_str.size > 2
      end#plot
      gp << "save '#{file_name}.plot'"
    end#gnuplot
    return File.basename(file_name)
  end
  
  def get_plot_filename(title , o = {})
    'img_' + (title.downcase.scan(/[a-z0-9]+/).join('_') + '.' +(o[:terminal] || 'png'))
  end
end
