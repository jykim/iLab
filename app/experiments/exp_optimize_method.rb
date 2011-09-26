

class SearchMethod
  def initialize(xvals , yvals , o = {})
    @ymax = o[:ymax] || 1.0
    @ymin = o[:ymin] || 0.0
    @step_size = o[:step_size] || (@ymax - @ymin) / 10
    @cvg_range = o[:cvg_range] || (@step_size / 10)
    @learn_rate = o[:learn_rate] || 1
    @xvals , @yvals , @o = xvals , yvals , o;
  end
end

# Plain grid search over two variables
class GridSearchMethod < SearchMethod
  def initialize(xvals , yvals , o = {})
    super(xvals, yvals, o)
    #@cvg_range = o[:cvg_range] || 0.0001
  end
  
  # get_set(0,1,0.1)
  # -> [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
  def get_set(start, finish, interval)
    cur_val = start; result = []
    while(cur_val < finish)
      result << cur_val
      cur_val += interval
    end
    result
  end
  
  def search(iter_count = 1, o = {})
    results = {}
    #For each value of parameter 1
    set = get_set(@ymin, @ymax, @step_size)
    set.each_with_index do |val_x , i|
      results[val_x] = {}
      set.each_with_thread do |val_y, j|
        results[val_x][val_y] = yield @xvals , [val_x,val_y] , :train, true
      end
    end#each point
    results
  end
end



class GradientSearchMethod < SearchMethod
  def initialize(xvals , yvals , o = {})
    super(xvals, yvals, o)
    #@cvg_range = o[:cvg_range] || 0.0001
  end  
  
  def converged?( results , cvg_range , test_time)
    return false
    converged = true
    results[-(test_time)..-1].each_cons(2){ |e| converged = false if e[1] - e[0] > cvg_range }
    converged
  end

  def search(iter_count , o = {})
    test_time = o[:test_time] || 7 # how many datapoints will be used for conv. test
    gradients = [] ; results = []
    0.upto(iter_count) do |i|
      gradients[i] = [] ; tg = ThreadGroup.new
      results[i] = yield @xvals , @yvals[i] , false
      puts "[#{i}] #{i}th iteration map = [#{results[i]}]"
      if i >= test_time and converged?( results , @cvg_range , test_time )
        puts "Covergence criteria has met!"
        break
      end
      #For each length point j
      @xvals.each_with_index do |cur_x , j|
        thr_xval  = Thread.new(i , j) do |i , j|
          cur_yvals = @yvals[i].dup
          cur_y = @yvals[i][j] ; cur_dir = nil
          cur_yvals[j] = case cur_y
                           when (@ymax - @step_size)..@ymax
                           cur_dir = '-' ; cur_y - @step_size
                           when @ymin...(@ymax - @step_size)
                           cur_dir = '+' ; cur_y + @step_size
                         end
          cur_result = yield @xvals , cur_yvals , true
          Thread.critical = true
          gradients[i][j] = (cur_dir=='+')? cur_result - results[i] : results[i] - cur_result
          Thread.critical = false
          puts "[#{i}][#{j}] gradient[#{cur_y.round_at(3)}] = #{gradients[i][j].round_at(3)}"
        end#thread
        tg.add thr_xval
      end#each point
      tg.list.each_with_index do |thr , j|
        thr.join
      end
      @yvals[i+1] = @yvals[i].map_with_index{|e,j| e + gradients[i][j] * @learn_rate}.
                    map{|e| (e>@ymax)? @ymax : e }.map{|e| (e<@ymin)? @ymin : e }
    end#iteration
    results
  end
end

# Variant of NeighborSectionSearchMethod where training is done in sequence
class SerialNeighborSectionSearchMethod < SearchMethod
  def search(iter_count , o = {})
    results = []
    1.upto(iter_count) do |i|
      results[i] = [] ; @yvals[i] = @yvals[i-1].dup
      #For each point j
      @xvals.each_with_index do |cur_x , j|
        results[i][j] = {}
        #For positive & negative direction
        ['+','-'].each do |cur_dir|
          cur_step = @step_size ; past_result = nil ; past_result2 = nil ; @yvals[i][j] = @yvals[i-1][j]
          valid_range = (cur_dir=='+')? (@yvals[i][j]..@ymax) : (@ymin..@yvals[i][j])
          while cur_step >= @cvg_range and valid_range ===  @yvals[i][j]
            cur_result  = yield @xvals , @yvals[i] , :train , $remote
            cur_result2 = yield @xvals , @yvals[i] , :tune , $remote if o[:tune_set]
            results[i][j][ @yvals[i][j]] = cur_result
            info "[#{i}][#{j}][#{cur_dir}] lambda[#{ @yvals[i][j].round_at(3)}] = #{cur_result.round_at(3)} #{valid_range} #{past_result}" 
            info "[#{i}][#{j}][#{cur_dir}/T] lambda[#{ @yvals[i][j].round_at(3)}] = #{cur_result2.round_at(3)}" if o[:tune_set]
            if !past_result or (cur_result > past_result and ( !o[:tune_set] || cur_result2 > past_result2))
              (cur_dir=='+')?  @yvals[i][j] += cur_step :  @yvals[i][j] -= cur_step
            elsif cur_dir=='+'
              cur_dir = '-' ; cur_step *= 0.5 ;  @yvals[i][j] -= cur_step
            elsif cur_dir=='-'
              cur_dir = '+' ; cur_step *= 0.5 ;  @yvals[i][j] += cur_step
            end
            past_result, past_result2 = cur_result, cur_result2
          end#while
        end#each direction
        @yvals[i][j] = results[i][j].max_pair[0]
      end#each point
      #@cvg_range *= 0.5 ; @step_size *= 0.5
    end#iteration
    results
  end
end

# Try to find max. performance configuration by trying nearer point first
# - move by @step_size until perf. gets better
# - step back in smaller step size when perf. starts to decrease
# - each X point is trained separately (therefore, in parallel)
class NeighborSectionSearchMethod < SearchMethod
  def search(iter_count , o = {})
    results = []
    1.upto(iter_count) do |i|
      #puts "## Starting #{i}th iteration ## #{@yvals[i-1].inspect}"
      results[i] = [] ; @yvals[i] = [] ; tg = ThreadGroup.new
      yield @xvals , @yvals[i-1] , :train, false
      #For each point j
      @xvals.each_with_index do |cur_x , j|
        results[i][j] = {}
        thr_xval  = Thread.new(i , j) do |i , j|
          #For positive & negative direction
          ['+','-'].each do |cur_dir|
            cur_step = @step_size ; cur_y = @yvals[i-1][j] ; past_result = nil
            valid_range = (cur_dir=='+')? cur_y..@ymax : @ymin..cur_y
            while cur_step >= cvg_range and valid_range === cur_y
              cur_yvals = @yvals[i-1].dup ; cur_yvals[j] = cur_y
              cur_result  = yield @xvals , cur_yvals , :train , true
              cur_result2 = yield @xvals , cur_yvals , :tune , true if o[:tune_set]
              #break if past_result == cur_result
              Thread.critical = true
              results[i][j][cur_y] = cur_result
              Thread.critical = false
              puts "[#{i}][#{j}][#{cur_dir}] lambda[#{cur_y.round_at(3)}] = #{cur_result.round_at(3)}"
              if !past_result or (cur_result > past_result and ( !o[:tune_set] || cur_result2 > past_result2))
                (cur_dir=='+')? cur_y += cur_step : cur_y -= cur_step
              elsif cur_dir=='+'
                cur_dir = '-' ; cur_step *= 0.5 ; cur_y -= cur_step
              elsif cur_dir=='-'
                cur_dir = '+' ; cur_step *= 0.5 ; cur_y += cur_step
              end
              past_result = cur_result
            end
          end#each direction
          Thread.critical = true
          # LESSON when this line was prossed after join, not all threads appeared...
          @yvals[i][j] = results[i][j].max_pair[0]
          Thread.critical = false
          #puts "[#{i}][#{j}] thread exited!"
        end#thread
        tg.add thr_xval
      end#each point
      tg.list.each_with_index do |thr , j|
        thr.join
        puts "[#{i}][#{j}] Final Value = #{@yvals[i][j]}"
      end
    end#iteration
    results
  end
end

# Find max perf. configuration of yvals for each of given xval
# - Try golden section search for each xval (http://en.wikipedia.org/wiki/Golden_section_search)
# - Changed into serial search, remembering the value found in previous x point (20080525)
class GoldenSectionSearchMethod < SearchMethod
  GOLDEN_RATIO = 0.381966
  def initialize(xvals , yvals , o = {})
    super(xvals, yvals, o)
    @cvg_range = o[:cvg_range] || 0.1
  end
  
  #Determine Appropriate Next Point
  def get_next_point(low_ys , high_ys , cur_y)
    #Current point is nearer to high_ys than low_ys
    if cur_y - low_ys.last > high_ys.last - cur_y
      high_ys << cur_y
      return low_ys.last + (cur_y - low_ys.last) * GOLDEN_RATIO
    else
      low_ys << cur_y
      return cur_y + (high_ys.last - cur_y) * GOLDEN_RATIO
    end
  end

  def search(iter_count , o = {})
    results = []
    1.upto(iter_count) do |i|
      results[i] = [] ; @yvals[i] = @yvals[i-1].dup
      #For each point j
      @xvals.each_with_index do |cur_x , j|
        results[i][cur_x] = {} #
        low_ys = [] ; high_ys = [] #lower & higher y points than cur_y
        low_ys << @ymin ; high_ys << @ymax ; k = 0 ; cur_y = -1

        #Iteration until convergence
        while (high_ys.last - low_ys.last) >= @cvg_range
          #Determine the next point to probe
          cur_y = case k
                  when 0 : @ymin
                  when 1 : @ymax
                  when 2 : GOLDEN_RATIO * (@ymax - @ymin) + @ymin
                  else get_next_point( low_ys , high_ys , cur_y ) #GOLDEN_RATIO*2 - GOLDEN_RATIO^2
                  end

          @yvals[i][cur_x] = cur_y
          results[i][cur_x][cur_y] = yield @xvals , @yvals[i]
          cur_result = "[#{i}][#{cur_x}] lambda[#{cur_y.round_at(3)}] = #{results[i][cur_x][cur_y]}"
          $lgr.info "#{i} #{cur_x} #{cur_y.round_at(5)} #{results[i][cur_x][cur_y]}"

          if k < 2 then k += 1 ; next end
          #low < cur & high < cur
          if results[i][cur_x][low_ys.last] < results[i][cur_x][cur_y] && results[i][cur_x][high_ys.last] < results[i][cur_x][cur_y]
            @yvals[i][cur_x] = cur_y
          #high < cur < low
          elsif results[i][cur_x][low_ys.last] >= results[i][cur_x][cur_y] && results[i][cur_x][high_ys.last] <= results[i][cur_x][cur_y]
            if k > 2
              high_ys << cur_y ; cur_y = low_ys.pop
            end
          #low < cur < high
          elsif results[i][cur_x][low_ys.last] <= results[i][cur_x][cur_y] && results[i][cur_x][high_ys.last] >= results[i][cur_x][cur_y]
            if k > 2
              low_ys << cur_y ; cur_y = high_ys.pop
            end
          #cur < high < low
          elsif results[i][cur_x][high_ys.last] < results[i][cur_x][low_ys.last]
            high_ys << cur_y ; cur_y = low_ys.pop
          #cur < low < high
          elsif results[i][cur_x][low_ys.last] <= results[i][cur_x][high_ys.last]
            low_ys << cur_y ; cur_y = high_ys.pop
          end

          if low_ys.size == 0
            puts "[#{i}][#{cur_x}] reached lower end" ; break        
          elsif high_ys.size == 0
            puts "[#{i}][#{cur_x}] reached upper end" ; break
          end
          puts "#{cur_result} -> #{low_ys.last.round_at(3)} - #{cur_y.round_at(3)} -  #{high_ys.last.round_at(3)}"
          k += 1
        end#while
        @yvals[i][cur_x] = results[i][cur_x].max_pair[0]
      end#each point
    end#iteration
    results
  end
end
