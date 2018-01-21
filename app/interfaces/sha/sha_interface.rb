module ShaInterface
  include WoodInterface

  methods do
    required_method :set_process, data:   String
    required_method :get_process, amount: Integer
    required_method :response
  end
end