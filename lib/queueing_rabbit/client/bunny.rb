require 'bunny'

module QueueingRabbit

  module Client

    class Bunny

      attr_reader :connection

      def self.connect
        self.new(::Bunny.new(QueueingRabbit.amqp_uri))
      end

      def open_channel(options = {})
        ch = connection.create_channel
        ch.confirm_select if !!options[:use_publisher_confirms]
        yield ch, nil
        ch
      end

      def define_queue(channel, name, options = {})
        queue = channel.queue(name.to_s, options)
        yield queue if block_given?
        queue
      end

      def bind_queue(queue, exchange, options = {})
        queue.bind(exchange, options)
      end

      def enqueue(exchange, payload, options = {})
        exchange.publish(payload, options)
      end
      alias_method :publish, :enqueue

      def define_exchange(channel = nil, name = '', options = {})
        type = options.delete(:type)

        exchange = type ? channel.send(type.to_sym, name, options) :
                          channel.default_exchange

        yield exchange if block_given?

        exchange
      end

      def queue_size(queue)
        queue.status[:message_count]
      end

    private

      def initialize(connection)
        @connection = connection
        @connection.start
      end

    end

  end

end