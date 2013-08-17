class PrintLineJob < QueueingRabbit::AbstractJob
  class << self
    attr_accessor :io
  end

  queue :print_line_job

  def perform
    self.class.io.puts payload
  end
end