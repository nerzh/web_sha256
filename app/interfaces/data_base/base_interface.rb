module BaseInterface
  include WoodInterface

  methods do
    required_method :get_data,    key: String
    required_method :set_data,    key: String, data: ''
    required_method :clear_data,  key: String
    required_method :new_data,    data: ''
  end
end