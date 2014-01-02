require 'spec_helper'
require 'integration/jobs/json_threaded_print_line_job'

describe "Synchronous publishing and threaded consuming", :ruby => '1.8.7' do
  include_context "Auto-disconnect"
  include_context "StringIO logger"

  context "basic consuming" do

    let(:line) { "Hello, world!" }
    let(:job) { JSONThreadedPrintLineJob }
    let(:job_name) { 'JSONThreadedPrintLineJob' }
    let(:io) { StringIO.new }
    let(:worker) { QueueingRabbit::Worker.new(job_name) }

    before do
      QueueingRabbit.purge_queue(job)
      Celluloid.logger = nil
      job.io = io
    end

    it "processes enqueued jobs" do
      worker.work

      3.times { job.enqueue(:line => line) }

      sleep 1

      job.queue_size.should be_zero
    end

    it "actually outputs the line" do
      worker.work

      job.enqueue(:line => line)

      sleep 0.5
      
      job.io.string.should include(line)
    end

    context 'on failure' do

      it "handles errors gracefully" do
        worker.work

        job.enqueue({:raise_error => 'Some very unique message'})

        sleep 0.5

        @session_log.string.should include('Some very unique message')
      end

    end

  end
  
end

