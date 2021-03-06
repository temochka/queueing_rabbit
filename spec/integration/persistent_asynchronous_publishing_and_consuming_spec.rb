require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Persistent asynchronous publishing and consuming" do
  include_context "Auto-disconnect"
  include_context "Evented spec"
  include_context "StringIO logger"

  before(:all) { QueueingRabbit.client = QueueingRabbit::Client::AMQP }
  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  context "basic consuming" do
    let(:line) { "Hello, world!" }
    let(:connection) { QueueingRabbit.connection }
    let(:job) {
      Class.new(PrintLineJob) do
        queue 'persistent_print_line_job'
        listen :manual_ack => true
        publish_with :persistent => true
        channel :use_publisher_confirms => true

        def perform
          super
          acknowledge
        end
      end
    }
    let(:job_name) { 'PrintLineWithAcknowledgmentsJob' }
    let(:io) { StringIO.new }
    let(:worker) { QueueingRabbit::Worker.new([job_name]) }

    before(:each) do
      QueueingRabbit.drop_connection
    end

    before do
      stub_const(job_name, job)
      job.io = io
    end

    it "processes enqueued jobs" do
      em {
        QueueingRabbit.connect
        @queue_size = nil

        def request_queue_size
          connection.open_channel do |c, _|
            connection.define_queue(c, job.queue_name, job.queue_options).status do |s, _|
              @queue_size = s
            end
          end
        end

        delayed(0.5) {
          3.times { job.enqueue(line) }
        }

        delayed(1.5) {
          request_queue_size
        }

        delayed(2.0) {
          @queue_size.should == 3
        }

        delayed(2.5) {
          worker.work
        }

        delayed(3.5) {
          request_queue_size
        }

        done(4.0) {
          @queue_size.should be_zero
        }
      }
    end

    it "actually outputs the line" do
      em {
        QueueingRabbit.connect

        delayed(0.5) { job.enqueue(line) }

        delayed(1.0) {
          worker.work
        }

        done(2.0) {
          io.string.should include(line)
        }
      }
    end
  end
end

