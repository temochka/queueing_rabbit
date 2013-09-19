module QueueingRabbit

  module Bus
    def self.extended(othermod)
      othermod.extend(QueueingRabbit::InheritableClassVariables)

      othermod.class_eval do
        inheritable_variables :channel_options, :exchange_name,
                              :exchange_options, :publishing_defaults
      end
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

    def publish_with(options = {})
      @publishing_defaults ||= {}
      @publishing_defaults.update(options)
    end

    def publishing_defaults
      @publishing_defaults || {}
    end

    def publish(payload, options = {})
      QueueingRabbit.publish(self, payload, publishing_defaults.merge(options))
    end
  end

end