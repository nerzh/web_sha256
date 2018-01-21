class Route
  
  attr_accessor :klass_name, :instance_method
  
  def initialize(route_hash)
    @klass_name      = route_hash[:klass]
    @instance_method = route_hash[:method]
  end

  def klass
    Module.const_get(klass_name + 'Controller')
  end

  def execute(env)
    klass.new(env).send(instance_method.to_sym)
  end
end