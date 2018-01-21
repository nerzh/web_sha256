require 'digest'

class Sha
  prepend ShaInterface

  attr_reader :base, :buffer, :block, :data, :input_data

  BUFFER_NAME  = 'buffer'
  STORAGE_NAME = 'storage'
  INDEX_NAME   = 'index'
  AMOUNT_ITEMS = 5

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
      write_storage
      indexing
      clear_buffer
    end
    @data = block
  end

  def get_process(amount)
    get_last_blocks(amount)
  end

  def response
    @data
  end

  private

  def get_last_blocks(amount)
    index_db   = read_index_db
    last_index = index_db.size - 1
    storage_db = read_storage
    
    amount.to_i.times do |order| 
      index = last_index - order
      break if index < 0
      @data << storage_db[index_db[index]]
    end
  end

  def clear_db
    base.clear_data(BUFFER_NAME)
    base.clear_data(STORAGE_NAME)
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
    read_storage.empty?
  end

  def read_storage
    base.get_data(STORAGE_NAME)
  end

  def write_storage
    db                      = read_storage
    db[block['block_hash']] = block
    base.set_data(STORAGE_NAME, db)
  end

  def read_index_db
    base.get_data(INDEX_NAME)
  end

  def indexing
    sorted_data = read_index_db
    sorted_data.empty? ? base.set_data(INDEX_NAME, [] << block['block_hash']) : base.set_data(INDEX_NAME, sorted_data << block['block_hash'])
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