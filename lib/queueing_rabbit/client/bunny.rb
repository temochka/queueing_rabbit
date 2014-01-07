require 'bunny'

module QueueingRabbit

  module Client

    class Bunny

      class Metadata

        def initialize(channel, delivery_info, properties)
          @channel = channel
          @delivery_info = delivery_info
          @properties = properties
        end

        def ack
          @channel.ack(@delivery_info.delivery_tag, false)
        end

        def headers
          @properties.headers
        end

      end

      include QueueingRabbit::Logging

      attr_reader :connection

      def self.connection_options
        {:connection_timeout => QueueingRabbit.tcp_timeout,
         :heartbeat => QueueingRabbit.heartbeat}
      end

      def self.connect
        self.new(::Bunny.new(QueueingRabbit.amqp_uri,
                 connection_options))
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
        options = options.dup
        type = options.delete(:type)

        exchange = type ? channel.send(type.to_sym, name, options) :
                          channel.default_exchange

        yield exchange if block_given?

        exchange
      end

      def queue_size(queue)
        queue.status[:message_count]
      end

      def listen_queue(queue, options = {})
        queue.subscribe(options) do |delivery_info, properties, payload|
          begin
            yield payload, Metadata.new(queue.channel, delivery_info, properties)
          rescue => e
            error "unexpected error #{e.class} occured: #{e.message}"
            debug e
          end
        end
      end

      def close
        @connection.close
      end

      def open?
        @connection.open?
      end

      def begin_worker_loop
        yield
        @connection.reader_loop.join
      end

    private

      def initialize(connection)
        @connection = connection
        @connection.start
      end

    end

  end

end