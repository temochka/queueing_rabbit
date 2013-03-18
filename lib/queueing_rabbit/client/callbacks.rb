module QueueingRabbit
  module Client
    module Callbacks
      def define_callback(name, &block)
        @callbacks ||= {}
        @callbacks[name] = block
      end

      def callback(name)
        @callbacks[name] if @callbacks
      end
    end
  end
end