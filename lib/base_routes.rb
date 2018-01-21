class BaseRoutes
  
  attr_reader :routes

  def initialize
    @routes = Hash.new { |hash, key| hash[key] = {} }
  end

  def config(&block)
    instance_eval(&block)
  end

  def get(path, options = {})
    routes[:get][path]        = {}
    routes[:get][path][:path] = path
    routes[:get][path]        = parse_to(options[:to])
  end

  def post(path, options = {})
    routes[:post][path]        = {}
    routes[:post][path][:path] = path
    routes[:post][path]        = parse_to(options[:to])
  end

  def route_for(env)
    path   = env["PATH_INFO"]
    method = env["REQUEST_METHOD"].downcase.to_sym
    routes[method].each do |routes_path, value|
      case routes_path
      when String
        return Route.new(routes[method][routes_path]) if path == routes_path
      when Regexp
        return Route.new(routes[method][routes_path]) if path =~ routes_path
      end
    end
    return nil #No route matched
  end

  private
  def parse_to(to_string)
    klass, method = to_string.split("#")
    {klass: klass.capitalize, method: method}
  end
end