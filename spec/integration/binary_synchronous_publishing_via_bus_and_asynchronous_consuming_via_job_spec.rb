require 'spec_helper'
require 'integration/jobs/print_line_job'

describe 'Binary synchronous publishing via bus and asynchronous consuming via job' do
  include_context "StringIO logger"
  include_context "Evented spec"
  
  let(:bus) {
    Class.new(QueueingRabbit::AbstractBus) do
      publish_with :routing_key => 'print_line_job'
    end
  }
  let(:job) { PrintLineJob }
  let(:worker) { QueueingRabbit::Worker.new(job.to_s) }
  let(:line) { "Hello, world!" }
  let(:io) { StringIO.new }

  before do
    job.io = io
    bus.publish(line)
    QueueingRabbit.drop_connection
  end

  it "works" do
    em {
      worker.work

      done(1.0) {
        io.string.should include(line)
      }
    }
  end
end