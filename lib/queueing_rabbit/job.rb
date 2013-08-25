module QueueingRabbit

  module Job

    def queue(*args)
      if args.first.kind_of?(Hash)
        @queue_options = args.first
      else
        @queue_name, @queue_options = args
      end
    end

    def queue_name
      @queue_name ||= self.name.split('::')[-1]
    end

    def queue_options
      @queue_options ||= {}
    end

    def queue_size
      QueueingRabbit.queue_size(self)
    end

    def channel(options={})
      @channel_options = options
    end

    def channel_options
      @channel_options ||= {}
    end

    def exchange(name, options = {})
      @exchange_name = name
      @exchange_options = options
    end

    def exchange_name
      @exchange_name
    end

    def exchange_options
      @exchange_options ||= {}
    end

    def bind(options = {})
      @binding_options = options
    end

    def binding_options
      @binding_options || nil
    end

    def bind_queue?
      exchange_options[:type] && exchange_options[:type] != :default && binding_options
    end

    def listening_options
      @listening_options || {}
    end

    def listen(options = {})
      @listening_options = options
    end

    def publishing_defaults(options = {})
      @publishing_defaults ||= options.merge(:routing_key => queue_name.to_s)
    end

    def enqueue(payload, options = {})
      QueueingRabbit.enqueue(self, payload, publishing_defaults.merge(options))
    end
    alias_method :publish, :enqueue

  end

end