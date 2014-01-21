require 'spec_helper'

describe "Synchronous batch publishing" do
  include_context "Auto-disconnect"
  include_context "Evented spec"
  include_context "StringIO logger"

  before(:all) { QueueingRabbit.client = QueueingRabbit::Client::Bunny }
  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  let(:line) { "Hello, world!" }
  let(:connection) { QueueingRabbit.connection }
  let(:job) {
    Class.new(QueueingRabbit::AbstractJob) do
      queue 'synchronous_batch_publishing'
    end
  }

  it 'produces 100 jobs in a batch' do
    em {
      delayed(0.5) {
        job.demand_batch_publishing!
      }

      delayed(1.0) {
        100.times { job.enqueue(line) }
      }

      done(3.0) {
        expect(QueueingRabbit.queue_size(job)).to eq(100)
        QueueingRabbit.purge_queue(job)
      }
    }
  end
  
end

