require 'rubylib_include'

class TestTable < Test::Unit::TestCase 
  def setup
    #debugger
    @tbl = Table.init_tbl("qid",[1,2,3])
    #p @tbl
  end
  
  def test_add_cols
    @tbl.add_cols(["t1","t2"], [[1,2],[2,3],[3,4]])
    p @tbl
    p @tbl.transpose
  end
  
  def test_transpose
    #@tbl.add_cols(["t1","t2"], [[1,2],[2,3],[3,4]])
  end
end 
