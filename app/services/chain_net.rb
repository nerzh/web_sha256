require 'json'
require 'net/http'
require 'uri'

module ChainNet

  class Http

    def self.send_post_data(url, data, ct='application/x-www-form-urlencoded')
      uri    = URI.parse(url)
      header = {'Content-Type': ct}
      # Create the HTTP objects
      http    = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      
      body = ''
      data.each do |key, value|
        body << (body.empty? ? "#{key}=#{value.to_json}" : "&#{key}=#{value.to_json}")
      end
      request.body = body

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