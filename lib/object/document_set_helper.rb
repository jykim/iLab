module DocumentSetHelper

  #Generate Input File from Term-Term Matirx
  def gen_doc( file_name , o = {})
    file_str = IO.read(file_name)
    out_prefix = o[:prefix] || File.basename(file_name, ".*")
    @matrix = (o[:full_matrix])? read_full_matrix(file_str) : read_sparse_matrix(file_str)
    
    @matrix.each_with_index do |row , i| #For each row
      row.each_with_index do |value , j| #For each column
        value.downto(1) do |n|
          @matrix[i][j] -= 1
          @matrix[j][i] -= 1 if @matrix[j][i] > 0 #in case of symmetric matrix
          fwrite sprintf("%s_C%02d_C%02d_%d.docu",out_prefix,i+1,j+1,n) , "C#{i+1} | C#{j+1}" , o
        end
      end
    end
  end
  
  def gen_term_list( o = {})
    seed_str = o[:seed_str] || "abcd "
    tno = o[:tno] || 1000
    mean_len = 20 ; var_len = 5
    
    terms = [] ; tno.downto(1) do |i|
      s = '' ; term_len = mean_len - var_len + rand(var_len*2)
      term_len.downto(1) {|k| s += seed_str.at(rand(seed_str.size)) }
      terms << s.scan(PTN_WORD).join(" ")
    end
    terms
  end
  
  # Array of Sparse Matrix -> String of Full Matrix
  def write_full_matrix(sparse)
    full = sparse_to_full(sparse)
  end
  
  # String of Full Matrix -> Array of Full Matrix
  def read_full_matrix(str)
    data = []
    CSV.parse(str) do |row|
      data << row.map{|e|e.to_i}
    end
    data
  end
  
  # String of Sparse Matrix -> Array of Full Matrix
  def read_sparse_matrix(str)
    sparse = str.split(SEP_LINE).map do |line|
      row , col , value = line.split(SEP_ITEM)
      [row.to_i , col.to_i , value.to_f]
    end
    sparse_to_full(sparse)
  end
  
  # Array of Sparse Matrix -> Array of Full Matrix
  # - Input index starts from 1 (for compatibility with other apps)
  # TODO Better Algorithm?
  def sparse_to_full(sparse , o = {})
    def_val = o[:def_val] || 0
    
    max_rno = sparse.map{|e|e[0]}.max
    max_cno = sparse.map{|e|e[1]}.max
    #full = Array.new( max_rno , Array.new(max_cno , def_val)) # LESSON Same Element is copied
    full = Array.new
    0.upto(max_rno-1) do |i|
      full[i] = Array.new if !full[i] 
      0.upto(max_cno-1){|j| full[i][j] = 0 }
    end
    #puts max_rno , max_cno , full.to_s
    sparse.each do |row|
      rno , cno , value = *row
      #uts "[#{rno},#{cno},#{value}]"
      full[rno-1][cno-1] = value
    end
    full
  end
end
