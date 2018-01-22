module DataBase
  class Base
    prepend BaseInterface

    attr_reader :client

    def initialize(client)
      @client = client
    end

    def set_data(key, data)
      client.set(key.to_s, data.to_json)
    end

    def get_data(key)
      new_data(client.get(key.to_s)).to_h
    end

    def clear_data(key)
      client.set(key.to_s, "{}")
    end

    def new_data(data)
      Data.new(data)
    end

    def delete_all
      client.del(*client.keys)
    end
  end

  class Data
    prepend DataInterface

    attr_reader :value

    def initialize(data)
      @value = (data&.empty? or data.nil?) ? '{}' : data
    end

    def to_h
      JSON.parse(@value)
    end
  end
end


