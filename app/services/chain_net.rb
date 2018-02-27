require 'json'
require 'net/http'
require 'uri'

module ChainNet

  class Http

    def self.send_post_data(url, data)
      uri    = URI.parse(url)
      # header = {'Content-Type': 'application/text/json'}
      header = {'Content-Type': 'application/x-www-form-urlencoded'}
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      
      body = ''
      data.each do |key, value|
        body << (body.empty? ? "#{key}=#{value.to_json}" : "&#{key}=#{value.to_json}")
      end
      request.body = body

      # Send the request
      response = http.request(request)
    end
  end
end