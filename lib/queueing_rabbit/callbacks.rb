module QueueingRabbit

  module Callbacks

    def before_consuming(&block)
      setup_callback(:worker_ready, &block)
    end

    def after_consuming(&block)
      setup_callback(:consuming_done, &block)
    end

    def on_consumer_error(&block)
      setup_callback(:consumer_error, &block)
    end

    def on_event_machine_start(&block)
      setup_callback(:event_machine_started, &block)
    end

    def setup_callback(event, &block)
      @callbacks ||= {}
      @callbacks[event] ||= []
      @callbacks[event] << block
    end

    def trigger_event(event, *args)
      if @callbacks && @callbacks[event]
        @callbacks[event].each { |c| c.call(*args) }
      end
    end

  end

end