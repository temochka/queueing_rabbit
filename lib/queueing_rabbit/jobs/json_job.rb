module QueueingRabbit

  class JSONJob < AbstractJob

    extend QueueingRabbit::Serializer

    alias_method :arguments, :payload

    def self.enqueue(payload, metadata = {})
      super serialize(payload), metadata
    end

    def initialize(payload, metadata = {})
      super self.class.deserialize(payload), metadata
    end

  end

end