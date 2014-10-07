require 'amqp'

module QueueingRabbit

  module Client

    class AMQP

      include QueueingRabbit::Logging
      extend  QueueingRabbit::Logging
      extend  QueueingRabbit::Client::Callbacks

      attr_reader :connection

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
        self.ensure_event_machine_is_running

        self.new(::AMQP.connect(QueueingRabbit.amqp_uri, connection_options))
      end

      def self.ensure_event_machine_is_running
        run_event_machine unless EM.reactor_running?
      end

      def self.run_event_machine
        @event_machine_thread = Thread.new do
          EM.run do
            QueueingRabbit.trigger_event(:event_machine_started)
          end
        end

        wait_for_event_machine_to_start
      end

      def self.wait_for_event_machine_to_start
        Timeout.timeout(5) do
          sleep 0.5 until EM.reactor_running?
        end
      rescue Timeout::Error => e
        description = "wait timeout exceeded while starting up EventMachine"
        fatal description
        raise QueueingRabbitError.new(description)
      end

      def self.join_event_machine_thread
        @event_machine_thread.join if @event_machine_thread
      end

      def open?
        EM.reactor_running? && @connection.open?
      end

      def close
        info "closing AMQP broker connection..."

        connection.disconnect do
          yield if block_given?

          EM.stop if EM.reactor_running?
        end
      end

      def define_queue(channel, queue_name, options={})
        channel.queue(queue_name.to_s, options) do |queue|
          yield queue if block_given?
        end
      end

      def bind_queue(queue, exchange, options = {})
        queue.bind(exchange, options)
      end

      def listen_queue(queue, options = {}, &block)
        queue.subscribe(options) do |metadata, payload|
          yield payload, metadata
        end
      end

      def open_channel(options = {})
        ::AMQP::Channel.new(connection, nil, options) do |c, open_ok|
          c.confirm_select if !!options[:use_publisher_confirms]
          c.on_error(&self.class.callback(:on_channel_error))
          yield c, open_ok
        end
      end

      def define_exchange(channel, name = '', options = {})
        options = options.dup
        type = options.delete(:type)
        with_exchange = Proc.new do |exchange, _|
          yield exchange if block_given?
        end

        if type && type != :default
          channel.send(type.to_sym, name, options, &with_exchange)
        else
          channel.default_exchange.tap(&with_exchange)
        end
      end

      def enqueue(exchange, payload, options = {})
        exchange.publish(payload, options)
      end
      alias_method :publish, :enqueue

      def queue_size(queue)
        raise NotImplementedError
      end

      def purge_queue(queue)
        queue.purge do
          yield if block_given?
        end
      end

      def next_tick(&block)
        EM.next_tick(&block)
      end

      def wait_while_for(proc, period, _ = nil, &block)
        if proc.call
          EM.add_timer(period, &block)
        else
          block.call
        end
      end

      def begin_worker_loop
        EM.run do
          yield if block_given?
        end
      end

    private

      def setup_callbacks
        connection.on_tcp_connection_loss(&self.class.callback(:on_tcp_loss))
        connection.on_recovery(&self.class.callback(:on_tcp_recovery))
      end

      def initialize(connection)
        @connection = connection

        setup_callbacks
      end

    end

  end

end