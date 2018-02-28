require 'digest'
require 'json'
require 'net/http'
require 'uri'

module ChainNet; end

module Chain

  class Process

    include ChainNet

    attr_reader :buffer, :block, :data, :input_data, :base, :start_hash, :port, :ip, :id, :name, :domain

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
      @domain     = attrs[:domain]
      # base.delete_all and raise 'CLEAR'
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
      get_last_blocks_as_linked_list(amount)
    end

    def add_link(address)
      write_link(address['id'], address)
      @data = address
    end

    def get_status
      @data = Status.new(id, name, link_prev_node, get_links, ip, port, start_hash, domain).to_h
    end

    def sync
      get_links.each do |link, value|
        url      = JSON.parse(value)['url']
        uri      = "#{url}/blockchain/get_blocks/10000"
        response = ChainNet::Http.send_get_data( uri )

        (delete_link(link); next) if response == nil

        @data = update_own_chain(response, link)
      end
    end

    def receive_update(input_data)
      input_block = input_data['block'].class == String ? JSON.parse(input_data['block']) : input_data['block']
      @block      = Chain::Block.new(block: input_block, prev_hash: link_prev_node, alien: true)

      if prev_node.empty? and block.hash == '0'
        add_alien_block(input_data)
        @data = block.to_h
        return
      end

      if block.prev_hash == prev_node['hash']
        add_alien_block(input_data)
        @data = block.to_h
        return
      end

      if block.prev_hash == link_prev_node and block.ts.to_i < prev_node['ts'].to_i

        delete_block(link_prev_node)
        add_alien_block(input_data)
        @data = block.to_h
      else
        raise "#{id} not found the own first block(0) in chain" if prev_node.empty?
        @data = prev_node
        url = JSON.parse(get_link(input_data['sender_id']))['url']
        raise "#{input_data['sender_id']} not found in list of adresses" if url.nil?
        data = { sender_id: id,  block: prev_node }
        ChainNet::Http.send_post_data( url << '/blockchain/receive_update', prev_node, 'text/plain')
      end
    end

    def response
      @data
    end

    private

    def update_own_chain(response, link)
      amount_new_blocks = 0
      data              = JSON.parse(response)
      last_block        = data.last['prev_hash'] == 0 ? data.first : data.last
      @block            = Chain::Block.new(block: last_block)
      add_block_stack(link)
      data.each do |blok|
        @block = Chain::Block.new(block: blok)
        amount_new_blocks += 1 unless get_block(block.hash).hash == ''
        write_new_block
      end
      amount_new_blocks
    end

    def add_alien_block(input_data)
      addresses   = get_links.keys
      return unless addresses.include?(input_data['sender_id'])

      add_block_stack(input_data['sender_id'])
      change_buffer_prev_link
    end

    def add_block_stack(skip='')
      write_new_block
      write_prev_node
      Thread.start { send_block_to_all_addresses(skip) }
    end

    def send_block_to_all_addresses(skip='')
      get_links.each do |link, value|
        next if link == skip
        url      = JSON.parse(value)['url']
        uri      = "#{url}/blockchain/receive_update"
        data     = { sender_id: id,  block: block.to_h }
        response = ChainNet::Http.send_post_data( uri, data, 'text/plain' )

        delete_link(link) if response == nil
      end
    end

    def get_last_blocks_as_linked_list(amount)
      return unless blockExist?
      @data = []
      prev_link = link_prev_node
      amount.times do |num|
        block = get_block(prev_link)
        @data.unshift(block.to_h)
        break if firstBlock?(prev_link)
        prev_link = block.prev_hash
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

    def get_links
      base.get_hash_all_data(ADDRESS_NAME)
    end

    def get_link(link)
      link = base.get_data(ADDRESS_NAME, link)
      link.empty? ? "{}" : link
    end

    def write_link(link, data)
      base.set_data(ADDRESS_NAME, link, data)
    end

    def delete_link(link)
      base.clear_data(ADDRESS_NAME, link)
    end

    def firstBlock?(link)
      link.to_i == start_hash.to_i
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

    def initialize(block: {}, prev_hash: '', start_hash: 0, alien: false)
      check_block(block) if alien

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
      hash['hash']      = @hash
      hash
    end

    private

    def check_block(block)
      raise 'empty block'                  if block.empty?
      raise 'prev_hash empty or not found' if block['prev_hash'] == nil or block['prev_hash'].empty?
      raise 'tx empty or size != 5'        if block['tx'] == nil        or block['tx'].size != 5
      raise 'ts empty or not found'        if block['ts'] == nil
      raise 'hash empty or not found'      if block['hash'] == nil      or block['hash'].empty?
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

    def initialize(id, name, link_prev_node, neighbours, ip, port, start_hash=0, domain=nil, protocol='http')
      @id         = id
      @name       = name
      @last_hash  = link_prev_node.empty? ? start_hash : link_prev_node
      @neighbours = neighbours.values.map { |val| JSON.parse(val) }
      @url        = protocol << '://' << (domain ? domain : ip) << ':' << port
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
