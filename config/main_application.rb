module SimpleApp
  class MainApplication
    
    def config
      yield(self) if block_given?
    end

    def call(env)
      route = InstanceRoute.route_for(env)
      if route
        response = route.execute(env)
        return response
      else
        return [404, {}, []]
      end
    end
  end
end