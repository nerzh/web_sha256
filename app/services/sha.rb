require 'digest'

class Sha
  prepend ShaInterface

  attr_reader :base, :buffer, :block, :data, :input_data

  BUFFER_NAME   = 'buffer'
  INDEX_NAME    = 'index'
  CURRENT_NODE  = 'current_node'
  AMOUNT_ITEMS  = 5

  def initialize(base)
    @base     = base
    # clear_db
    @block    = clean_buffer? ? init_block : read_buffer
    @data     = []
  end

  def set_process(input_data)
    @input_data = input_data
    update_block

    if check_data_size
      write_buffer
    else
      write_new_block
      write_current_node
      indexing
      clear_buffer
    end
    @data = block
  end

  def get_process(amount)
    get_last_blocks_as_linked_list(amount)
  end

  def response
    @data
  end

  private

  def get_last_blocks_as_linked_list(amount)
    return if firstBlock?
    current_node = read_current_node
    amount.to_i.times do |order|
      @data << current_node
      break if current_node['previous_block_hash'] == 0
      current_node = base.get_data(current_node['previous_block_hash'])
    end
  end

  def get_first_blocks(amount)
    index_db = read_index_db
    size     = index_db.size
    amount.to_i.times do |order|
      break if order == size
      @data << base.get_data(index_db[order])
    end
  end

  def clear_db
    base.clear_data(BUFFER_NAME)
    base.clear_data(CURRENT_NODE)
    base.clear_data(INDEX_NAME)
  end

  def clear_buffer
    base.clear_data(BUFFER_NAME)
  end

  def read_buffer
    base.get_data(BUFFER_NAME)
  end

  def write_buffer
    base.set_data(BUFFER_NAME, block)
  end

  def clean_buffer?
    read_buffer.empty?
  end

  def check_data_size
    block['rows'].size < AMOUNT_ITEMS
  end

  def firstBlock?
    base.get_data(CURRENT_NODE).empty?
  end

  def write_new_block
    base.set_data(block['block_hash'], block)
  end

  def read_index_db
    base.get_data(INDEX_NAME)
  end

  def indexing
    sorted_data = read_index_db
    sorted_data.empty? ? base.set_data(INDEX_NAME, [] << block['block_hash']) : base.set_data(INDEX_NAME, sorted_data << block['block_hash'])
  end

  def read_current_node
    base.get_data(CURRENT_NODE)
  end

  def write_current_node
    base.set_data(CURRENT_NODE, block['block_hash'])
  end

  def unix_time
    Time.now.to_i
  end

  def encode_data(string)
    Digest::SHA256.hexdigest(string)
  end

  def make_data_string
    str = ''
    str << block['previous_block_hash'].to_s
    str << block['rows'].to_s
    str << block['timestamp'].to_s
  end

  def init_block
    @block                       = {}
    block['previous_block_hash'] = firstBlock? ? 0 : read_index_db.last
    block['rows']                = []
    block['timestamp']           = 0
    block['block_hash']          = ''
    block
  end

  def update_block
    block['rows']       << input_data
    block['timestamp']   = unix_time
    block['block_hash']  = encode_data(make_data_string)
  end
end