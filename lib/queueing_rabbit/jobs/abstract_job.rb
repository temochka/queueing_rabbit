module QueueingRabbit

  class AbstractJob

    extend Job

    attr_reader :payload, :metadata

    def initialize(payload, metadata)
      @payload = payload
      @metadata = metadata
    end

    def acknowledge
      metadata.ack
    end

    def headers
      metadata.headers
    end

    def perform
    end

  end

end