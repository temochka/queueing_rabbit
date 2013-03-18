require 'amqp'

module QueueingRabbit

  module Client

    class AMQP

      include QueueingRabbit::Serializer
      include QueueingRabbit::Logging
      extend  QueueingRabbit::Logging
      extend  QueueingRabbit::Client::Callbacks

      attr_reader :connection, :exchange_name, :exchange_options

      define_callback :on_tcp_failure do |_|
        fatal "unable to establish TCP connection to broker"
        EM.stop
      end

      define_callback :on_tcp_loss do |c, _|
        info "re-establishing TCP connection to broker"
        c.reconnect(false, 1)
      end

      define_callback :on_tcp_recovery do
        info "TCP connection to broker is back and running"
      end

      define_callback :on_channel_error do |ch, channel_close|
        EM.stop
        fatal "channel error occured: #{channel_close.reply_text}"
      end

      def self.connection_options
        {:timeout => QueueingRabbit.tcp_timeout,
         :heartbeat => QueueingRabbit.heartbeat,
         :on_tcp_connection_failure => self.callback(:on_tcp_failure)}
      end

      def self.connect
        self.run_event_machine

        self.new(::AMQP.connect(QueueingRabbit.amqp_uri),
                 QueueingRabbit.amqp_exchange_name,
                 QueueingRabbit.amqp_exchange_options)
      end

      def self.run_event_machine
        return if EM.reactor_running?

        @event_machine_thread = Thread.new do
          EM.run do
            QueueingRabbit.trigger_event(:event_machine_started)
          end
        end
      end

      def self.join_event_machine_thread
        @event_machine_thread.join if @event_machine_thread
      end

      def disconnect
        info "closing AMQP broker connection..."

        connection.close do
          yield if block_given?

          EM.stop { exit }
        end
      end

      def define_queue(channel, queue_name, options={})
        routing_keys = [*options.delete(:routing_keys)] + [queue_name]

        channel.queue(queue_name.to_s, options) do |queue|
          routing_keys.each do |key|
            queue.bind(exchange(channel), :routing_key => key.to_s)
          end
        end
      end

      def listen_queue(channel, queue_name, options={}, &block)
        define_queue(channel, queue_name, options)
            .subscribe(:ack => true) do |metadata, payload|
          begin
            process_message(deserialize(payload), &block)
            metadata.ack
          rescue JSON::JSONError => e
            error "JSON parser error occured: #{e.message}"
            debug e
          end
        end
      end

      def process_message(arguments)
        begin
          yield arguments
        rescue => e
          error "unexpected error #{e.class} occured: #{e.message}"
          debug e
        end
      end

      def open_channel(options={})
        ::AMQP::Channel.new(connection,
                          ::AMQP::Channel.next_channel_id,
                          options) do |c, open_ok|
          c.on_error(&self.class.callback(:on_channel_error))
          yield c, open_ok
        end
      end

      def define_exchange(channel, options={})
        channel.direct(exchange_name, exchange_options.merge(options))
      end
      alias_method :exchange, :define_exchange

      def enqueue(channel, routing_key, payload)
        exchange(channel).publish(serialize(payload), :key => routing_key.to_s,
                                                      :persistent => true)
      end
      alias_method :publish, :enqueue

    private

      def setup_callbacks
        connection.on_tcp_connection_loss(&self.class.callback(:on_tcp_loss))
        connection.on_recovery(&self.class.callback(:on_tcp_recovery))
      end

      def initialize(connection, exchange_name, exchange_options)
        @connection = connection
        @exchange_name = exchange_name
        @exchange_options = exchange_options

        setup_callbacks
      end

    end

  end

end