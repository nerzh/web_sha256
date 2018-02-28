require 'json'
require 'net/http'
require 'uri'

module ChainNet

  class Http

    def self.send_post_data(url, data, ct='application/x-www-form-urlencoded')
      uri     = URI.parse(url)
      header  = {'Content-Type'=> ct}
      http    = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      
      body = ''
      data.each do |key, value|
        key   = (key.class == Array or key.class == Hash) ? key.to_json : key
        value = (value.class == Array or value.class == Hash) ? value.to_json : value
        body << (body.empty? ? "#{key}=#{value}" : "&#{key}=#{value}")
      end
      ct == 'application/x-www-form-urlencoded' ? request.body = body : request.body = data.to_json

      # Send the request
      http.request(request)
    rescue => ex
      nil
    end

    def self.send_get_data(url, data={}, headers={})
      url = URI.parse(url)
      Net::HTTP.get(url)
    rescue => ex
      nil
    end
  end
end