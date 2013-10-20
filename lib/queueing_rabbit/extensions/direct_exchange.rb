module QueueingRabbit

  module JobExtensions

    module DirectExchange

      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        def exchange_options
          @exchange_options ||= {}
          @exchange_options.merge(:type => :direct)
        end

        def binding_declarations
          @binding_declarations ||= []
          @binding_declarations.push(:routing_key => queue_name.to_s)
        end
      end

    end

  end

end