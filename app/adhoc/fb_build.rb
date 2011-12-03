File.open("fbuser2.qry",'w'){|f|f.puts IO.read("fbuser2.q").gsub(/\.[a-z]+/,"")}
File.open("fbuser3.qry",'w'){|f|f.puts IO.read("fbuser3.q").gsub(/\.[a-z]+/,"")}
File.open("fbuser4.qry",'w'){|f|f.puts IO.read("fbuser4.q").gsub(/\.[a-z]+/,"")}

[jykim@sydney facebook]$ ln -s /mnt/nfs/work2/cjlee/TestCollection/fb-user2 index_fb2
