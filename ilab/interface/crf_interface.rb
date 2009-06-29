
class CRFInterface
  include ILabHelper
  def initialize()
  end
  
  def train(input, model, o={})
    crf_c = o[:crf_c] || 1.0
    template = $o[:crf_template] || $o[:col_type] || $col
    fwrite('crf_train.log' , `crf_learn -c #{crf_c} #{to_path("crfpp_#{template}.template")} #{to_path(input)} #{to_path(model)}`, :mode=>'a')
  end
  
  def test(input, model, output, o={})
    #if !fcheck(output)
      fwrite('crf_test.log' , `crf_test -v2 -m #{to_path(model)} #{to_path(input)} > #{to_path(output)}`, :mode=>'a')
    #end
    col_no = fread(input).split("\n").find_all{|e|e.size > 15}[0].split(" ").size
    info "[CRFInterface::test] col_no = #{col_no}"
    s = fread(output)
     precs = []
     result = s.split("\n\n").map_with_index do |q,i|
       cnt_total, cnt_right = 0.0, 0.0
       #puts "col_no=#{col_no} q=#{q}"
       #For each query
       result_query = q.split("\n").find_all{|e|e.size > 15}.map do |qw|
         #Foreach query-word
         a = qw.split("\t")
         cnt_total += 1
         cnt_right += 1 if a[col_no-1] == a[col_no].split("/")[0]
         mp = a[col_no+1..-1].map{|e|a2 = e.split("/"); [a2[0], a2[1].to_f]}
         [a[0].downcase,mp]
       end
       precs << cnt_right/cnt_total
       result_query
     end
     [precs,result]
  end
  
end
