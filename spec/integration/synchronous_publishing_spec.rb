require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Synchronous publishing example",
         QueueingRabbit::Client::Bunny do
  include_context "StringIO logger"

  let(:job) { PrintLineJob }

  context "when publishing a message" do
    after do
      QueueingRabbit.purge_queue(job)
    end

    let(:publishing) {
      -> { QueueingRabbit.publish(job, line: "Hello, World!") }
    }

    it 'affects the queue size' do
      expect { 5.times { publishing.call } }
        .to change{QueueingRabbit.queue_size(job)}.by(5)
    end
  end

end