module ChainBlockInterface
  include WoodInterface

  methods do
    required_method :make_data_string
    required_method :to_h
    required_method :previous_block_hash
    required_method :rows
    required_method :timestamp
    required_method :block_hash
  end
end