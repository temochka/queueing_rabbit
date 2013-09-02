module QueueingRabbit
  module InheritableClassVariables
    def inheritable_variables(*args)
      @inheritable_variables ||= [:inheritable_variables]
      @inheritable_variables += args
    end

    def inherited(subclass)
      @inheritable_variables ||= []
      @inheritable_variables.each do |var|
        if !subclass.instance_variable_get("@#{var}") ||
           subclass.instance_variable_get("@#{var}").empty?
          subclass.instance_variable_set("@#{var}",
                                         instance_variable_get("@#{var}"))
        end
      end
    end
  end

  module Job
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

    def channel(options = {})
      @channel_options ||= {}
      @channel_options.update(options)
    end

    def channel_options
      @channel_options ||= {}
    end

    def exchange(*args)
      @exchange_options ||= {}
      if args.first.kind_of?(Hash)
        @exchange_options.update(args.first)
      elsif args.count > 1
        name, options = args
        @exchange_name = name
        @exchange_options.update(options)
      else
        @exchange_name = args.first
      end
    end

    def exchange_name
      @exchange_name || ''
    end

    def exchange_options
      @exchange_options || {}
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

    def publish(options = {})
      @publishing_defaults ||= {}
      @publishing_defaults.update(options)
    end

    def publishing_defaults
      @publishing_defaults ||= {}
      {:routing_key => queue_name.to_s}.merge(@publishing_defaults)
    end

    def enqueue(payload, options = {})
      QueueingRabbit.enqueue(self, payload, publishing_defaults.merge(options))
    end

  end

end