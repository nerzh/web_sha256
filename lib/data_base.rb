module DataBase
  class Base

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def set_data(table, key, data)
      client.hset(table, key, data.to_json)
    end

    def get_data(table, key)
      new_data(client.hget(table, key)).to_h
    end

    def get_hash_all_data(table)
      client.hgetall(table)
    end

    def clear_data(table, key)
      client.del(table, key.to_s)
    end

    def clear_table(table)
      client.del(table)
    end

    def new_data(data)
      Data.new(data)
    end

    def delete_all
      client.del(*client.keys) unless client.keys.empty?
    end
  end

  class Data

    attr_reader :value

    def initialize(data)
      @value = (data&.empty? or data.nil?) ? "{}" : data
    end

    def to_h
      JSON.parse(@value)
    end
  end
end


