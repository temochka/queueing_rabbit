module QueueingRabbit

  module Configuration
    attr_accessor :amqp_uri
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

    def jobs_wait_timeout
      @jobs_wait_timeout ||= 5
    end

    def default_client
      QueueingRabbit::Client::Bunny
    end
  end

end