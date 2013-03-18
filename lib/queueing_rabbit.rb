require "queueing_rabbit/version"
require "queueing_rabbit/callbacks"
require "queueing_rabbit/configuration"
require "queueing_rabbit/logging"
require "queueing_rabbit/serializer"
require "queueing_rabbit/client/callbacks"
require "queueing_rabbit/client/amqp"
require "queueing_rabbit/client/bunny"
require "queueing_rabbit/job"
require "queueing_rabbit/worker"
# require "queueing_rabbit/new_relic"

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

  def drop_connection
    @connection = nil
  end

  def enqueue(job, arguments = {})
    info "enqueueing job #{job} with arguments: #{arguments.inspect}."

    connection.open_channel(job.channel_options) do |c, _|
      connection.define_queue(c, job.queue_name, job.queue_options)
      connection.enqueue(c, job.queue_name, arguments)
    end

    true
  end
  alias_method :publish, :enqueue

  def queue_size(job)
    connection.open_channel(job.channel_options) do |c, _|
      queue = connection.define_queue(c, job.queue_name, job.queue_options)
      connection.queue_size(queue)
    end
  end
end

QueueingRabbit.client = QueueingRabbit::Client::Bunny
QueueingRabbit.logger = Logger.new(STDOUT)