module QueueingRabbit

  module Callbacks

    def before_consuming(&block)
      setup_callback(:consuming_started, &block)
    end

    def after_consuming(&block)
      setup_callback(:consuming_done, &block)
    end

    def on_event_machine_start(&block)
      setup_callback(:event_machine_started, &block)
    end

    def setup_callback(event, &block)
      @callbacks ||= {}
      @callbacks[event] ||= []
      @callbacks[event] << block
    end

    def trigger_event(event)
      if @callbacks && @callbacks[event]
        @callbacks[event].each { |c| c.call }
      end
    end

  end

end