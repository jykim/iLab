#Scripts for DIH
#Truncate first line of file
s = IO.read('queries.txt').sub!(/^T.*?\n/,"") ; nil
File.open('queries.txt',"w"){|f|f.puts s}

#Produce Perf. Summary from the grep output of trec_eval files
load 'ilab.rb'
s = IO.read('pd_1006np_result.txt') ; nil
pid = ['c0161','c0141']
col_type = ['html','lists','pdf','msword','ppt','xl']
topic_type=['F_TF_FF','F_TIDF_FF','F_RN_subject','F_IDF','F_RN','D_TF','D_TIDF','D_RN']
method_type=['DQL','PRM']
s.split("\n").each{|l|e = l.split("|");puts [pid.pfind(e[0]), col_type.pfind(e[0]), topic_type.pfind(e[0])].concat(e[2..-1]).join("|")} ; nil 

#Produce Perf. for Different Field Mapping
load 'ilab.rb'
s = IO.read('fm_c0141_lists.txt') ; nil
s.split("\n").each{|l|e = l.split("_");puts [e[4], l].join(" ")} ; nil 


#Generate Known-item Topics (from manual topics)
load 'ilab.rb'
a = IO.read('manual_topics.0909').split("\n").map{|e|a=e.split(/\s+/); [a[0],a[1..-1].join(" ")]}
build_knownitem_topic("topic_c0161_lists_manual", "qrel_c0161_lists_manual", :queries=>a)

#-------

#Get the ratio of documents from each collection from resultset file

['0318b','0318c','0318d'].each do |id|
  ['F_RN_TIDF','F_RN_TF','F_RN_IDF','F_RN_RN','D_TF','D_TIDF','D_IDF','D_RN'].each do |type|
    ['DQL','PRM-S','PRM-D'].each do |method|
      analyze_col_ratio("c0161_all_#{type}_#{id}", method)
    end
  end
end

['c0002','c0141','c0161'].each do |pid|
  $cs_types.each do |cs_type| #$cs_types
    NORM_TYPES.each do |norm_type|
      analyze_col_ratio("#{pid}_all_F_RN_RN_0708b", "PRM-S_cw0.4_#{norm_type}_#{cs_type}")
    end
  end
end
