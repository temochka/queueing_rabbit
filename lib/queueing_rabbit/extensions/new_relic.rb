module QueueingRabbit

  module JobExtensions

    module NewRelic

      def self.included(klass)
        if klass.respond_to?(:perform)
          add_for_class_method(klass)
        else
          add_for_instance_method(klass)
        end
      end

      def self.add_for_class_method(klass)
        klass.class_eval do |k|
          class << k
            include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
            add_transaction_tracer :perform, :category => :task
          end
        end
      end

      def self.add_for_instance_method(klass)
        klass.class_eval do |k|
          include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
          add_transaction_tracer :perform, :category => :task
        end
      end

    end

  end

end
