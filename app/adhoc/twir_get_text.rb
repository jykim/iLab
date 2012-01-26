#require 'rubygems'
#require 'json'
require 'net/http'
require 'timeout.rb'

def get_text( file , ofile, format )
  File.open( file ) do |f|
    File.open( ofile, 'w' ) do |of|
      while line = f.gets
        begin
          #id, hash, url =* line.split(/\s+/)
          dt = line.split(/\t/)
          hash, url = dt[6], dt[7]
          Dir.mkdir(format) if !File.exist?(format)
          if File.exist?("#{format}/#{hash}.#{format}")
            puts "#{hash}, #{url} already found!"
            next
          end
          puts "#{hash}, #{url}"
          api_url = "http://viewtext.org/api/text?url=#{url}&format=#{format}"
          timeout(7) do
            content = Net::HTTP.get(URI.parse(api_url))
            of.puts "#{hash}\t#{content.size}"
            File.open( "#{format}/#{hash}.#{format}",'w'){|of2|of2.puts content}
          end
        rescue TimeoutError
          puts "Timeout in [#{line}]"
        rescue Exception => e
          puts "Error in [#{line}]",e
        end
        sleep(0.5)
      end
    end
  end
end

get_text( ARGV[0], ARGV[0]+'.out', 'html')
#get_text( ARGV[0], ARGV[0]+'.out', 'xml')

def get_tags( file , ofile, format )
  File.open( file ) do |f|
    File.open( ofile, 'w' ) do |of|
      while line = f.gets
        #begin
          batch, id, hash, url =* line.split(/\s+/)
          puts "#{id}, #{hash}, #{url}"
          api_url = "curl https://lifidea:1275dkjy@api.del.icio.us/v1/posts/suggest?url=#{url}"
          puts api_url
          content = `#{api_url}`#Net::HTTP.get(URI.parse(api_url))
          of.puts "#{hash}\t#{content.size}\t#{url}"
          #Dir.mkdir(format) if !File.exist?(format)
          File.open( "tags/#{hash}.#{format}",'w'){|of2|of2.puts content}
        #rescue Exception => e
        #  puts "Error in [#{line}]",e
        #end
        sleep(1)
      end
    end
  end
end

#get_tags( ARGV[0], ARGV[0]+'.tags', 'xml')


def get_clicks( file , ofile, format )
  File.open( file ) do |f|
    File.open( ofile, 'w' ) do |of|
      while line = f.gets
        #begin
          batch, id, hash, url =* line.split(/\s+/)
          api_key = "R_12855747ed682ddadbfdc9425eab0bb8"
          #access_token = "ed0f9b209a3cfbdac11e246afb9bb9581591a195"#{}"1f7683b87663b59c5417e60ab5a9b7f014bea063"
          puts "#{id}, #{hash}, #{url}"
          api_url = "curl https://api-ssl.bitly.com/v3/clicks?login=lifidea&apiKey=#{api_key}&shortUrl=#{url}"
          #api_url = "curl https://api-ssl.bitly.com/v3/clicks?access_token=#{access_token}&shortUrl=#{url}"
          puts api_url
          content = `#{api_url}`#Net::HTTP.get(URI.parse(api_url))
          of.puts "#{hash}\t#{content.size}\t#{url}"
          #Dir.mkdir(format) if !File.exist?(format)
          File.open( "clicks/#{hash}.#{format}",'w'){|of2|of2.puts content}
        #rescue Exception => e
        #  puts "Error in [#{line}]",e
        #end
        sleep(1)
      end
    end
  end
end

#get_clicks( ARGV[0], ARGV[0]+'.clicks', 'xml')

