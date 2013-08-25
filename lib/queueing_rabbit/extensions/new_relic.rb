module QueueingRabbit

  module JobExtensions

    module NewRelic

      def self.included(klass)
        if klass.respond_to?(:perform)
          klass.class_eval do |k|
            class << k
              include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
              add_transaction_tracer :perform, :category => :task
            end
          end
        else
          klass.class_eval do |k|
            include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
            add_transaction_tracer :perform, :category => :task
          end
        end
      end

    end

  end

end
