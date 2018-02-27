require 'digest'
require 'json'
require 'net/http'
require 'uri'

module ChainNet; end

module Chain

  class Process

    include ChainNet

    attr_reader :buffer, :block, :data, :input_data, :base, :start_hash, :port, :ip, :id, :name

    BUFFER_NAME   = 'buffer'
    PREV_NODE     = 'prev_node'
    CHAIN_NAME    = 'chain'
    ADDRESS_NAME  = 'addresses'
    AMOUNT_ITEMS  = 5

    def initialize(**attrs)
      @base       = attrs[:base]
      @start_hash = attrs[:start_hash]
      @port       = attrs[:port]
      @ip         = attrs[:ip]
      @id         = attrs[:id]
      @name       = attrs[:name]
      # base.delete_all
      # raise ''
      @block    = Chain::Block.new(block: read_buffer, prev_hash: link_prev_node)
      @data     = {}
    end

    def add_transaction(input_data)
      @input_data = input_data
      update_block

      if check_data_size
        write_buffer
      else
        add_block_stack
        clear_buffer
      end

      @data = block.to_h
    end

    def get_blocks(amount)
      # ChainNet::Http.send_post_data('http://localhost:3001/blockchain/t', {a: {z: 'dsdsdsd', e: 222}, m: [1,2,3] } )
      get_last_blocks_as_linked_list(amount)
    end

    def add_link(address)
      addresses = base.get_data(ADDRESS_NAME, ADDRESS_NAME)
      base.set_data(ADDRESS_NAME, ADDRESS_NAME, addresses.empty? ? {}.merge({address['id'] => address}) : addresses.merge({address['id'] => address}))
      @data = address
    end

    def get_status
      @data = Status.new(id, name, link_prev_node, base.get_data(ADDRESS_NAME, ADDRESS_NAME), ip, port).to_h
    end

    def sync
      @data = base.get_hash_all_data(CHAIN_NAME).values
    end

    def receive_update(input_data)

      if prev_node.empty? and input_data['block']['hash'] == '0' 
        add_alien_block(input_data['block'])
      end

      if input_data['block']['prev_hash'] == prev_node['hash']
        add_alien_block(input_data['block'])
        return
      end

      if input_data['block']['prev_hash'] == link_prev_node and input_data['block']['ts'] < prev_node['ts']
        delete_block(link_prev_node)
        add_alien_block(input_data['block'])
      else
        send_post_data(base.get_data(ADDRESS_NAME)[input_data['sender_id']]['url'] + 'receive_update', block.to_h)
      end
    end

    def response
      @data
    end

    private

    def add_alien_block(input_data)
      @block = Chain::Block.new(input_data, link_prev_node)
      add_block_stack
      change_buffer_prev_link
    end

    def add_block_stack
      write_new_block
      write_prev_node
      Thread.start { send_block_to_addresses }
    end

    def send_block_to_addresses
      base.get_data(ADDRESS_NAME, ADDRESS_NAME).each do |key, value|
        ChainNet::Http.send_post_data(value['url'] + '/receive_update', block.to_h)
      end
    end

    def get_last_blocks_as_linked_list(amount)
      return unless blockExist?
      @data = Array.new(amount)
      prev_link = link_prev_node
      amount.times do |num|
        block = get_block(prev_link).to_h
        @data[amount-(num+1)] = block
        break if firstBlock?(prev_link)
        prev_link = block['prev_hash']
      end
    end

    def clear_buffer
      base.clear_data(BUFFER_NAME, BUFFER_NAME)
    end

    def read_buffer
      base.get_data(BUFFER_NAME, BUFFER_NAME)
    end

    def write_buffer
      base.set_data(BUFFER_NAME, BUFFER_NAME, block.to_h)
    end

    def change_buffer_prev_link
      base.set_data(BUFFER_NAME, 'prev_hash', link_prev_node)
    end

    def check_data_size
      block.tx.size < AMOUNT_ITEMS
    end

    def blockExist?
      !base.client.hkeys(PREV_NODE).empty?
    end

    def prev_node
      base.get_data(CHAIN_NAME, link_prev_node)
    end

    def get_block(hash)
      Chain::Block.new(block: base.get_data(CHAIN_NAME, hash))
    end

    def write_new_block
      base.set_data(CHAIN_NAME, block.hash, block.to_h)
    end

    def delete_block(hash)
      base.clear_data(CHAIN_NAME, hash)
    end

    def link_prev_node
      base.get_data(PREV_NODE, PREV_NODE)
    end

    def write_prev_node
      base.set_data(PREV_NODE, PREV_NODE, block.hash)
    end

    def firstBlock?(link)
      link == start_hash
    end

    def unix_time
      Time.now.to_i
    end

    def encode_data(string)
      Digest::SHA256.hexdigest(string)
    end

    def update_block
      block.tx    << Balance.new(input_data).to_h
      block.ts    = unix_time
      block.hash  = encode_data(block.make_data_string)
    end
  end


  class Block

    attr_accessor :prev_hash, :tx, :ts, :hash

    def initialize(block: {}, prev_hash: '', start_hash: 0)
      unless block.empty?
        @prev_hash = block['prev_hash']
        @tx        = block['tx']
        @ts        = block['ts']
        @hash      = block['hash']
      else
        @prev_hash = prev_hash.empty? ? start_hash : prev_hash
        @tx        = []
        @ts        = 0
        @hash      = ''
      end
    end

    def make_data_string
      str = ''
      str << prev_hash.to_s
      str << ts.to_s
      tx.each do |transaction|
        str << transaction['from'].to_s
        str << transaction['to'].to_s
        str << transaction['amount'].to_s
      end
      str
    end

    def to_h
      hash = {}
      hash['prev_hash'] = prev_hash
      hash['tx']        = tx
      hash['ts']        = ts
      hash['hash']      = self.hash
      hash
    end
  end

  class Balance
    attr_accessor :from, :to, :amount

    def initialize(input_data)
      @from      = input_data['from']
      @to        = input_data['to']
      @amount    = input_data['amount']
    end

    def to_h
      {'from' => from, 'to' => to, 'amount' => amount}
    end
  end

  class Status
    attr_accessor :id, :name, :last_hash, :neighbours, :url

    def initialize(id, name, link_prev_node, neighbours, ip, port)
      @id         = id
      @name       = name
      @last_hash  = link_prev_node.empty? ? start_hash : link_prev_node
      neighbours.class == Hash ? @neighbours = neighbours.keys : @neighbours = {}
      @url        = 'http://' << ip << ':' << port
    end

    def to_h
      hash               = {}
      hash['id']         = id
      hash['name']       = name
      hash['last_hash']  = last_hash
      hash['neighbours'] = neighbours
      hash['url']        = url
      hash
    end
  end
end




# curl -X POST -H "Content-Type: application/json" -d '{"id": 94, "name": "GOSPODIN_BUG", "url": "192.168.44.94:3000"}' "http://b54e0cb5.ngrok.io/add_node"
