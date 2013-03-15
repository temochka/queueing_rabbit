require 'json'

module QueueingRabbit
  module Serializer
    def serialize(args)
      JSON.dump(args)
    end

    def deserialize(msg)
      symbolize_keys(JSON.parse(msg))
    end

  private

    def symbolize_keys(hash)
      hash.inject({}) { |memo, (k,v)| memo[k.to_sym] = v; memo }
    end
  end
end