require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Synchronous publishing and consuming with JSON serialization" do
  include_context "Auto-disconnect"
  include_context "StringIO logger"

  context "basic consuming" do
    let(:line) { "Hello, world!" }
    let(:job) {
      Class.new(QueueingRabbit::JSONJob) do
        class << self
          attr_accessor :io
        end

        def perform
          PrintLineFromJSONJob.io.puts arguments[:line]
        end
      end
    }
    let(:job_name) { 'PrintLineFromJSONJob' }
    let(:io) { StringIO.new }
    let(:worker) { QueueingRabbit::Worker.new(job_name) }

    before do
      job.io = io
      stub_const(job_name, job)
    end

    after do
      QueueingRabbit.drop_connection
    end

    it "processes enqueued jobs" do
      3.times { job.enqueue(:line => line) }
      job.queue_size.should == 3
      worker.work
      job.queue_size.should be_zero
    end

    it "actually outputs the line" do
      job.enqueue(:line => line)
      worker.work
      job.io.string.should include(line)
    end

  end
  
end

