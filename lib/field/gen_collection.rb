module GenCollection
  # Generate document with metadata from the collection
  # @param String doc_id
  # @param Array fields : {:tag=>, :content=>}
  def generate_doc(path, doc_id, fields , o = {})
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    File.open("#{path}/#{doc_id}.xml", "w"){|f| f.puts template.result(binding)}
    puts "[gen_doc] #{doc_id} file created"
  end
  
  # Get synthetic term distribution 
  def get_syn_tdist(prefix, term_no)
    (1..term_no).to_a.map_hash{|i|[prefix+i.to_s, 1.0/i]}
  end
  
  # Generate Collection Documents
  def build_collection(col_id, doc_no, field_no, mix_ratio = 0.5, term_no = 20, field_size = 10, doc_size = 200)
    clm = get_syn_tdist("c", term_no)
    flms = (1..field_no).to_a.map_hash{|i| 
      ["f#{i}", get_syn_tdist(i.to_s+"f", term_no).smooth(mix_ratio, clm)] }
    fsizes = flms.map_hash{|k,v|[k,field_size]}
    flms["clm"], fsizes["clm"] = clm, doc_size - field_size * field_no
    template = ERB.new(IO.read(to_path("doc_trectext.xml.erb")))
    #p flms

    File.open(to_path("#{col_id}.trecweb"),"w") do |f|
      1.upto(doc_no) do |i|
        doc_id = "D#{i}"
        fields = flms.map{|k,v|
          {:tag=>k, :content=>v.to_p.sample_pdist(fsizes[k]).join(" ")}}
        f.puts template.result(binding)
      end
    end
  end
end