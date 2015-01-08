require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Synchronous publishing and asynchronous consuming example" do
  include_context "Auto-disconnect"
  include_context "StringIO logger"
  include_context "Evented spec"

  let(:job) { PrintLineJob }
  let(:line) { "Hello, world!" }

  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  context "when a message is published synchronously and being consumed " \
          "asynchornously" do
    let(:worker) { QueueingRabbit::Worker.new([job.to_s]) }
    let(:io) { StringIO.new }

    before do
      job.io = io
      job.enqueue(line)
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

end