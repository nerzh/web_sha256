require 'digest'

module Chain

  START_HASH = '0'

  class Process
  
    prepend ChainProcessInterface

    attr_reader :base, :buffer, :block, :data, :input_data

    BUFFER_NAME   = 'buffer'
    INDEX_NAME    = 'index'
    PREV_NODE     = 'prev_node'
    AMOUNT_ITEMS  = 5

    def initialize(base)
      @base     = base
      # clear_db; raise ''
      @block    = Chain::Block.new(read_buffer, link_prev_node)
      @data     = []
    end

    def set_process(input_data)
      @input_data = input_data
      update_block

      if check_data_size
        write_buffer
      else
        write_new_block
        write_prev_node
        indexing
        clear_buffer
      end
      @data = block.to_h
    end

    def get_process(amount)
      get_last_blocks_as_linked_list(amount)
    end

    def response
      @data
    end

    private

    def get_last_blocks_as_linked_list(amount)
      return unless blockExist?
      prev_link = link_prev_node
      amount.to_i.times do
        block = base.get_data(prev_link)
        @data << block
        break if firstBlock?(prev_link)
        prev_link = block['previous_block_hash']
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
      base.client.del(*base.client.keys)
    end

    def clear_buffer
      base.clear_data(BUFFER_NAME)
    end

    def read_buffer
      base.get_data(BUFFER_NAME)
    end

    def write_buffer
      base.set_data(BUFFER_NAME, block.to_h)
    end

    def clean_buffer?
      read_buffer.empty?
    end

    def check_data_size
      block.rows.size < AMOUNT_ITEMS
    end

    def blockExist?
      !base.get_data(PREV_NODE).empty?
    end

    def write_new_block
      base.set_data(block.block_hash, block.to_h)
    end

    def read_index_db
      base.get_data(INDEX_NAME)
    end

    def indexing
      sorted_data = read_index_db
      sorted_data.empty? ? base.set_data(INDEX_NAME, [] << block.block_hash) : base.set_data(INDEX_NAME, sorted_data << block.block_hash)
    end

    def link_prev_node
      base.get_data(PREV_NODE)
    end

    def write_prev_node
      base.set_data(PREV_NODE, block.block_hash.to_s)
    end

    def firstBlock?(link)
      link == Chain::START_HASH
    end

    def unix_time
      Time.now.to_i
    end

    def encode_data(string)
      Digest::SHA256.hexdigest(string)
    end

    def update_block
      block.rows       << input_data
      block.timestamp   = unix_time
      block.block_hash  = encode_data(block.make_data_string)
    end
  end



  class Block

    prepend ChainBlockInterface

    attr_accessor :previous_block_hash, :rows, :timestamp, :block_hash

    def initialize(buffer, previous_block_hash)
      unless buffer.empty?
        @previous_block_hash = buffer['previous_block_hash']
        @rows                = buffer['rows']
        @timestamp           = buffer['timestamp']
        @block_hash          = buffer['block_hash']
      else
        @previous_block_hash = previous_block_hash.empty? ? Chain::START_HASH : previous_block_hash
        @rows                = []
        @timestamp           = 0
        @block_hash          = ''
      end
    end

    def make_data_string
      str = ''
      str << previous_block_hash.to_s
      str << rows.to_s
      str << timestamp.to_s
    end

    def to_h
      hash = {}
      hash['previous_block_hash'] = previous_block_hash
      hash['rows']                = rows
      hash['timestamp']           = timestamp
      hash['block_hash']          = block_hash
      hash
    end
  end
end