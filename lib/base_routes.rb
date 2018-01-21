class BaseRoutes
  
  attr_reader :routes, :bufer_params

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
    @bufer_params = {}
    path          = env["PATH_INFO"]
    method        = env["REQUEST_METHOD"].downcase.to_sym
    routes[method].each do |route, value|
      case route
      when String
        return Route.new(routes[method][route], @bufer_params) if check_string_path(path, route)
      when Regexp
        return Route.new(routes[method][route]) if path =~ route
      end
    end
    return nil #No route matched
  end

  private
  
  def parse_to(to_string)
    klass, method = to_string.split("#")
    {klass: klass.capitalize, method: method}
  end

  def check_string_path(path, route)
    return true if path == route
    args = separation(path, route)
    return false unless is_param_route?(route) and equal_number_parts?(*args)
    check_params(*args)
  end

  def is_param_route?(route)
    route[/:[^\/]+/] != nil
  end

  def separation(path, route)
    path  = path.strip.gsub(/^\/|\/$/, '').split('/')
    route = route.strip.gsub(/^\/|\/$/, '').split('/')
    [path, route]
  end

  def equal_number_parts?(path_parts, route_parts)
    path_parts.size == route_parts.size
  end

  def check_params(path_parts, route_parts)
    route_parts.each_with_index do |part, index|
      key = part.sub(/^:/, '')
      if is_param_route?(part)
        @bufer_params[key] = path_parts[index]
      else
        return false if part != path_parts[index]
      end
    end
    true
  end
end


