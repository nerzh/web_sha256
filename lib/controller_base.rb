class Controller
  class Base
    attr_accessor :env, :request, :response
    
    def initialize(env)
      @env = env
      @request  = Rack::Request.new(env)
      @response = Rack::Response.new
    end

    def render(template = '', **args)
      if args[:json]
        response.body = [ args[:json].to_json ]
        return response
      end

      self.class.to_s.downcase =~ /^(.+)controller$/
      name_controller = $1
      template = caller_locations.first.label if template == ''

      path = File.expand_path("../../app/views/#{name_controller}/#{template.to_s}.html.haml", __FILE__)
      path_layout = File.expand_path("../../app/views/layout.html.haml", __FILE__)
      
      block = lambda{ Haml::Engine.new(File.read(path)).render(binding) }
      response.body = [ Haml::Engine.new(File.read(path_layout)).render { block.call } ]
      response
    end

    def redirect(url)
      response.redirect(url)
      response
    end

    def params
      request.params
    end
  end
end