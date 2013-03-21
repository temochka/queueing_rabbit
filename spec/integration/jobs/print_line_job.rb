class PrintLineJob
  extend QueueingRabbit::Job

  class << self
    attr_writer :io
  end

  queue :print_line_job, :durable => true

  def self.perform(arguments = {})
    self.io.puts arguments[:line]
  end

  def self.io
    @io ||= STDOUT
  end
end