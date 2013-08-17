require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Synchronous publishing example" do
  include_context "StringIO logger"

  let(:job) { PrintLineJob }

  before do
    job.io = StringIO.new
  end

  context "when publishing a message" do
    after do
      QueueingRabbit.purge_queue(job)
    end

    let(:publishing) {
      Proc.new { job.enqueue("Hello, World!") }
    }

    it 'affects the queue size' do
      expect { 5.times(&publishing) }.
             to change{QueueingRabbit.queue_size(job)}.by(5)
    end
  end

end