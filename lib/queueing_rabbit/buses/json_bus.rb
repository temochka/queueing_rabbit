module QueueingRabbit

  class JSONBus < AbstractBus

    extend QueueingRabbit::Serializer

    def self.publish(payload, metadata = {})
      super serialize(payload), metadata
    end

  end

end