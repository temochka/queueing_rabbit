module QueueingRabbit

  module JobExtensions

    module DirectExchange

      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        def exchange_options
          @exchange_options ||= {}
          @exchange_options.update(:type => :direct)
        end

        def binding_options
          @binding_options || {:routing_key => queue_name.to_s}
        end
      end

    end

  end

end