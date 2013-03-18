module QueueingRabbit
  module Job
    def queue_name
      @queue_name ||= self.name.split('::')[-1]
    end

    def queue_options
      @queue_options ||= {}
    end

    def queue(name, options = {})
      @queue_name = name
      @queue_options = options
    end

    def queue_size
      QueueingRabbit.queue_size(self)
    end

    def channel_options
      @channel_options ||= {}
    end

    def channel(options={})
      @channel_options = options
    end
  end

  class AbstractJob
    extend Job
  end
end
