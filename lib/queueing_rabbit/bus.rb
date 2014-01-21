module QueueingRabbit

  module Bus
    def self.extended(othermod)
      othermod.extend(QueueingRabbit::InheritableClassVariables)

      othermod.class_eval do
        inheritable_variables :channel_options, :exchange_name,
                              :exchange_options, :publishing_defaults
      end
    end

    attr_reader :shared_exchange

    def channel(options = {})
      @channel_options ||= {}
      @channel_options.update(options)
    end

    def channel_options
      @channel_options ||= {}
    end

    def exchange(*args)
      @exchange_options ||= {}
      name, options = extract_name_and_options(*args)
      @exchange_name = name if name
      @exchange_options.update(options) if options
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

    def demand_batch_publishing!
      QueueingRabbit.follow_bus_requirements(self) do |_, exchange|
        @shared_exchange = exchange
      end
    end

    def batch_publishing?
      !!@shared_exchange
    end

    def publish(payload, options = {}, method = :publish)
      args = [payload, publishing_defaults.merge(options)]
      
      if batch_publishing?
        QueueingRabbit.publish_to_exchange(@shared_exchange, *args)
      else
        QueueingRabbit.send(method, self, *args)
      end
    end

    protected

    def extract_name_and_options(*args)
      name = options = nil
      if args.first.kind_of?(Hash)
        options = args.first
      elsif args.count > 1
        name, options = args
      else
        name = args.first
      end
      [name, options]
    end
  end

end