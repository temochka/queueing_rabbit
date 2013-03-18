class PrintLineJob
  extend QueueingRabbit::Job

  class << self
    attr_accessor :io
  end

  queue :print_line_job, :durable => true

  def self.perform(arguments = {})
    self.io.puts arguments[:line]
  end
end