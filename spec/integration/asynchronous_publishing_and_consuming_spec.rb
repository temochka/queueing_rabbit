require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Asynchronous publishing and consuming example" do
  include_context "Evented spec"
  include_context "StringIO logger"

  let(:job) { PrintLineJob }

  before(:all) { QueueingRabbit.client = QueueingRabbit::Client::AMQP }
  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  context "basic consuming" do
    let(:connection) { QueueingRabbit.connection }
    let(:worker) { QueueingRabbit::Worker.new(job.to_s) }
    let(:io) { StringIO.new }
    let(:line) { "Hello, world!" }

    before(:each) do
      QueueingRabbit.drop_connection
      PrintLineJob.io = io
    end

    it "processes enqueued jobs" do
      em {
        QueueingRabbit.connect
        queue_size = nil

        delayed(0.5) {
          3.times { QueueingRabbit.enqueue(job, :line => line) }
        }

        delayed(1.0) { worker.work }

        delayed(2.0) {
          connection.open_channel do |c, _|
            connection.define_queue(c, :print_line_job, job.queue_options).status do |s, _|
              queue_size = s
            end
          end
        }

        done(3.0) { queue_size.should == 0 }
      }
    end

    it "actually outputs the line" do
      em {
        QueueingRabbit.connect

        delayed(0.5) { QueueingRabbit.enqueue(job, :line => line) }

        delayed(1.0) { worker.work }

        done(2.0) {
          io.string.should include(line)
        }
      }
    end
  end
end

