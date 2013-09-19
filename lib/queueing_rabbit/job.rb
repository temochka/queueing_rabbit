module QueueingRabbit

  module Job
    include Bus

    def self.extended(othermod)
      othermod.extend(QueueingRabbit::InheritableClassVariables)

      othermod.class_eval do
        inheritable_variables :queue_name, :queue_options, :channel_options,
                              :exchange_name, :exchange_options,
                              :binding_options, :listening_options,
                              :publishing_defaults
      end
    end

    def queue(*args)
      @queue_options ||= {}
      if args.first.kind_of?(Hash)
        @queue_options.update(args.first)
      elsif args.count > 1
        name, options = args
        @queue_name = name
        @queue_options.update(options)
      else
        @queue_name = args.first
      end
    end

    def queue_name
      @queue_name || (self.name.split('::')[-1] if self.name)
    end

    def queue_options
      @queue_options || {}
    end

    def queue_size
      QueueingRabbit.queue_size(self)
    end

    def bind(options = {})
      @binding_options ||= {}
      @binding_options.update(options)
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
      @listening_options ||= {}
      @listening_options.update(options)
    end
    alias_method :subscribe, :listen

    def publishing_defaults
      @publishing_defaults ||= {}
      {:routing_key => queue_name.to_s}.merge(@publishing_defaults)
    end

    def enqueue(payload, options = {})
      QueueingRabbit.enqueue(self, payload, publishing_defaults.merge(options))
    end

  end

end