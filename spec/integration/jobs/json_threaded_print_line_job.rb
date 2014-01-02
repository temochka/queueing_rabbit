require 'queueing_rabbit/extensions/threaded'

class JSONThreadedPrintLineJob < QueueingRabbit::JSONJob

  class << self
    attr_accessor :io
  end

  include QueueingRabbit::JobExtensions::Threaded

  queue :auto_delete => true

  listen :ack => true,
         :block => false,
         :consumer_tag => 'threaded-json-consumer'

  def perform
    raise arguments[:raise_error] if arguments[:raise_error]

    self.class.io.puts arguments[:line]
    acknowledge
  end

end
