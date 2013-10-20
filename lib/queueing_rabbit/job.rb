module QueueingRabbit

  module Job
    include Bus

    def self.extended(othermod)
      othermod.extend(QueueingRabbit::InheritableClassVariables)

      othermod.class_eval do
        inheritable_variables :queue_name, :queue_options, :channel_options,
                              :exchange_name, :exchange_options,
                              :binding_declarations, :listening_options,
                              :publishing_defaults
      end
    end

    def queue(*args)
      @queue_options ||= {}
      name, options = extract_name_and_options(*args)
      @queue_name = name if name
      @queue_options.update(options) if options
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
      @binding_declarations ||= []
      @binding_declarations << options
    end

    def binding_declarations
      @binding_declarations || []
    end

    def bind_queue?
      exchange_options[:type] &&
          exchange_options[:type] != :default &&
          !binding_declarations.empty?
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