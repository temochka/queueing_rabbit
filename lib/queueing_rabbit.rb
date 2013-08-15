require "queueing_rabbit/version"
require "queueing_rabbit/callbacks"
require "queueing_rabbit/configuration"
require "queueing_rabbit/logging"
require "queueing_rabbit/serializer"
require "queueing_rabbit/client/callbacks"
require "queueing_rabbit/client/amqp"
require "queueing_rabbit/client/bunny"
require "queueing_rabbit/extensions/new_relic"
require "queueing_rabbit/job"
require "queueing_rabbit/worker"

module QueueingRabbit
  extend self
  extend Logging
  extend Callbacks
  extend Configuration

  class QueueingRabbitError < Exception; end
  class JobNotFoundError < QueueingRabbitError; end
  class JobNotPresentError < QueueingRabbitError; end

  attr_accessor :logger, :client

  def connect
    @connection ||= client.connect
  end

  def connection
    @connection ||= connect
  end
  alias_method :conn, :connection

  def drop_connection
    @connection = nil
  end

  def enqueue(job, payload = nil, options = {})
    if payload.respond_to?(:to_s)
      info "enqueueing job #{job} with payload: #{payload}"
    end

    follow_job_requirements(job) do |_, exchange, _|
      conn.enqueue(exchange, payload, options)
    end

    true
  end
  alias_method :publish, :enqueue

  def follow_job_requirements(job)
    conn.open_channel(job.channel_options) do |ch, _|
      conn.define_exchange(ch, job.exchange_name, job.exchange_options) do |ex|
        conn.define_queue(ch, job.queue_name, job.queue_options) do |q|
          conn.bind_queue(q, ex, job.binding_options)
          yield ch, ex, q if block_given?
        end
      end

      ch.close
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
      connection.define_queue(c, job.queue_name, job.queue_options).purge
      c.close
    end
    true
  end
end

QueueingRabbit.client = QueueingRabbit.default_client
QueueingRabbit.logger = Logger.new(STDOUT)