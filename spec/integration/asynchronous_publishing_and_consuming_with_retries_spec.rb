require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Asynchronous publishing and consuming with retries" do
  include_context "Auto-disconnect"
  include_context "Evented spec"
  include_context "StringIO logger"

  before(:all) { QueueingRabbit.client = QueueingRabbit::Client::AMQP }
  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  context "basic consuming" do
    let(:line) { "Hello, world!" }
    let(:connection) { QueueingRabbit.connection }
    let(:job) {
      Class.new(QueueingRabbit::AbstractJob) do
        class << self
          attr_accessor :io, :times_executed
        end

        include QueueingRabbit::JobExtensions::Retryable
        queue 'retryable_print_line_job'

        def perform
          self.class.times_executed = self.class.times_executed.to_i + 1
          if retries > 2
            self.class.io << 'Hello, world!'
          else
            retry_upto(3)
          end
        end
      end
    }
    let(:job_name) { 'RetryablePrintLineJob' }
    let(:io) { StringIO.new }
    let(:worker) { QueueingRabbit::Worker.new([job_name]) }

    before(:each) do
      QueueingRabbit.drop_connection
    end

    before do
      job.io = io
      stub_const(job_name, job)
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
          job.times_executed.should == 12
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

