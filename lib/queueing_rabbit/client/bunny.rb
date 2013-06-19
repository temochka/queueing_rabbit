require 'bunny'

module QueueingRabbit

  module Client

    class Bunny

      include QueueingRabbit::Serializer

      attr_reader :connection, :exchange_name, :exchange_options

      def self.connect
        self.new(::Bunny.new(QueueingRabbit.amqp_uri),
                 QueueingRabbit.amqp_exchange_name,
                 QueueingRabbit.amqp_exchange_options)
      end

      def open_channel(options = {})
        ch = connection.create_channel
        yield ch, nil
        # ch.close
      end

      def define_queue(channel, name, options = {})
        routing_keys = ([*options.delete(:routing_keys)] + [name]).compact

        queue = channel.queue(name.to_s, options)

        routing_keys.each do |key|
          queue.bind(exchange(channel), :routing_key => key.to_s)
        end

        queue
      end

      def enqueue(channel, routing_key, payload)
        exchange(channel).publish(serialize(payload), :key => routing_key.to_s,
                                                      :persistent => true)
      end
      alias_method :publish, :enqueue

      def define_exchange(channel, options={})
        channel.direct(exchange_name, exchange_options.merge(options))
      end
      alias_method :exchange, :define_exchange

      def queue_size(queue)
        queue.status[:message_count]
      end

    private

      def initialize(connection, exchange_name, exchange_options)
        @connection = connection
        @exchange_name = exchange_name
        @exchange_options = exchange_options

        @connection.start
      end

    end

  end

end