class Route
  
  attr_accessor :klass_name, :instance_method, :params
  
  def initialize(route_hash, params)
    @params          = params
    @klass_name      = route_hash[:klass]
    @instance_method = route_hash[:method]
  end

  def klass
    Module.const_get(klass_name + 'Controller')
  end

  def execute(env)
    klass.new(env, params).send(instance_method.to_sym)
  end
end