module QueueingRabbit

  module Configuration
    attr_accessor :amqp_uri, :amqp_exchange_name, :amqp_exchange_options
    attr_writer :tcp_timeout, :heartbeat

    def configure
      yield self
    end

    def tcp_timeout
      @tcp_timeout ||= 1
    end

    def heartbeat
      @heartbeat ||= 10
    end
  end

end