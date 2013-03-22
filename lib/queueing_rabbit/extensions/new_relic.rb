module QueueingRabbit

  module Extensions

    module NewRelic

      def self.included(mod)
        mod.class_eval do |klass|
          class << klass
            include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
            add_transaction_tracer :perform, category: :task
          end
        end
      end

    end

  end

end
