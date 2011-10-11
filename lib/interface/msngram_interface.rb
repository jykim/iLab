require 'net/http'

def get_msngram(operation, par = {})
  catalog = 'bing-body'
  version = 'jun09'
  order = 3
  parameter = par.merge("u"=>"52f34dff-0f84-4f30-9bd2-7e25f0e3dc8c")#.map{|k,v|"#{k}=#{v}"}.join("&")
  request_uri = URI.parse("http://web-ngram.research.microsoft.com/rest/lookup.svc/#{catalog}/#{version}/#{order}/#{operation}")
  result_text = Net::HTTP.post(request_uri, parameter)
end
