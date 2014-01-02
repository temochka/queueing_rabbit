require 'spec_helper'
require 'integration/jobs/print_line_job'

describe 'JSON synchronous publishing via bus and asynchronous consuming via job' do
  include_context "Auto-disconnect"
  include_context "StringIO logger"
  include_context "Evented spec"
  
  let(:bus) {
    Class.new(QueueingRabbit::JSONBus) do
      publish_with :routing_key => 'print_line_job'
    end
  }
  let(:job) {
    Class.new(QueueingRabbit::JSONJob) do
      class << self
        attr_accessor :io
      end

      queue 'print_line_job'

      def perform
        self.class.io.puts arguments[:line]
      end
    end
  }
  let(:job_name) { 'PrintLineJob' }
  let(:worker) { QueueingRabbit::Worker.new(job_name) }
  let(:line) { "Hello, world!" }
  let(:io) { StringIO.new }

  before do
    stub_const(job_name, job)
  end

  before do
    job.io = io
    bus.publish(:line => line)
    QueueingRabbit.drop_connection
    QueueingRabbit.client = QueueingRabbit::Client::AMQP
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