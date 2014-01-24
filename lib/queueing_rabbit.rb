require "queueing_rabbit/version"
require "queueing_rabbit/misc/inheritable_class_variables"
require "queueing_rabbit/callbacks"
require "queueing_rabbit/configuration"
require "queueing_rabbit/logging"
require "queueing_rabbit/serializer"
require "queueing_rabbit/client/callbacks"
require "queueing_rabbit/client/amqp"
require "queueing_rabbit/client/bunny"
require "queueing_rabbit/extensions/new_relic"
require "queueing_rabbit/extensions/retryable"
require "queueing_rabbit/extensions/direct_exchange"
require "queueing_rabbit/bus"
require "queueing_rabbit/buses/abstract_bus"
require "queueing_rabbit/buses/json_bus"
require "queueing_rabbit/job"
require "queueing_rabbit/jobs/abstract_job"
require "queueing_rabbit/jobs/json_job"
require "queueing_rabbit/worker"

module QueueingRabbit
  extend self
  extend Logging
  extend Callbacks
  extend Configuration
  extend MonitorMixin

  class QueueingRabbitError < Exception; end
  class JobNotFoundError < QueueingRabbitError; end
  class JobNotPresentError < QueueingRabbitError; end

  attr_accessor :logger, :client

  def connect
    synchronize do
      @connection ||= client.connect
    end
  end
  alias_method :conn, :connect
  alias_method :connection, :connect

  def disconnect
    synchronize do
      if connected?
        @connection.close
      end
      drop_connection
    end
  end

  def connected?
    @connection && @connection.open?
  end

  def drop_connection
    @connection = nil
  end

  def enqueue(job, payload = nil, options = {})
    info "enqueueing job #{job}"

    follow_job_requirements(job) do |channel, exchange, _|
      publish_to_exchange(exchange, payload, options)
      channel.close
    end

    true
  end

  def publish(bus, payload = nil, options = {})
    info "publishing to event bus #{bus}"

    follow_bus_requirements(bus) do |channel, exchange|
      publish_to_exchange(exchange, payload, options)
      channel.close
    end

    true
  end

  def publish_to_exchange(exchange, payload = nil, options = {})
    conn.publish(exchange, payload, options)
    true
  end

  def begin_worker_loop
    conn.begin_worker_loop do
      yield
    end
  end

  def follow_job_requirements(job)
    follow_bus_requirements(job) do |ch, ex|
      conn.define_queue(ch, job.queue_name, job.queue_options) do |q|
        if job.bind_queue?
          job.binding_declarations.each { |o| conn.bind_queue(q, ex, o) }
        end

        yield ch, ex, q
      end
    end
  end

  def follow_bus_requirements(bus)
    conn.open_channel(bus.channel_options) do |ch, _|
      conn.define_exchange(ch, bus.exchange_name, bus.exchange_options) do |ex|
        yield ch, ex
      end
    end
  end

  def queue_size(job)
    size = 0
    connection.open_channel(job.channel_options) do |c, _|
      queue = connection.define_queue(c, job.queue_name, job.queue_options)
      size = connection.queue_size(queue)
      c.close
    end
    size
  end

  def purge_queue(job)
    connection.open_channel(job.channel_options) do |c, _|
      connection.define_queue(c, job.queue_name, job.queue_options) do |q|
        connection.purge_queue(q) { c.close }
      end
    end
    true
  end
end

QueueingRabbit.client = QueueingRabbit.default_client
QueueingRabbit.logger = Logger.new(STDOUT)