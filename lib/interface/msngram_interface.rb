require 'net/http'

# 
def get_msngram(operation, data, par = {})
  catalog = 'bing-body'
  version = 'jun09'
  order = 3
  parameter = par.merge("u"=>"52f34dff-0f84-4f30-9bd2-7e25f0e3dc8c").map{|k,v|"#{k}=#{v}"}.join("&")
  #request_uri = URI.parse("http://web-ngram.research.microsoft.com/rest/lookup.svc/#{catalog}/#{version}/#{order}/#{operation}?#{parameter}")
  begin
    http = Net::HTTP.new("web-ngram.research.microsoft.com")
    resp, result = http.post("/rest/lookup.svc/#{catalog}/#{version}/#{order}/#{operation}?#{parameter}", data)
    if resp.code == "200"
      #puts "[get_msngram] #{data} => #{result}"
      result.split("\n").map{|e|e.to_f}
    else
      return [0.0]
    end    
  rescue Exception => e
    return [0.0]
  end
  # Get Request
  #request_uri = URI.parse("http://web-ngram.research.microsoft.com/rest/lookup.svc/#{catalog}/#{version}/#{order}/#{operation}?#{parameter}")
  #Net::HTTP.get(request_uri)
end
