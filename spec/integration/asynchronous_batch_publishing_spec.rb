require 'spec_helper'

describe "Asynchronous batch publishing" do
  include_context "Auto-disconnect"
  include_context "Evented spec"
  include_context "StringIO logger"

  before(:all) { QueueingRabbit.client = QueueingRabbit::Client::AMQP }
  after(:all) { QueueingRabbit.client = QueueingRabbit.default_client }

  let(:line) { "Hello, world!" }
  let(:connection) { QueueingRabbit.connection }
  let(:job) {
    Class.new(QueueingRabbit::AbstractJob) do
      queue 'asynchronous_batch_publishing'
    end
  }

  it 'produces 100 jobs in a batch' do
    em {
      @queue_size = 0

      def request_queue_size
        connection.open_channel do |c, _|
          connection.define_queue(c, job.queue_name, job.queue_options).status do |s, _|
            @queue_size = s
          end
        end
      end

      delayed(0.5) {
        job.demand_batch_publishing!
      }

      delayed(1.0) {
        100.times { job.enqueue(line) }
      }

      delayed(3.0) {
        request_queue_size
      }

      delayed(3.5) {
        QueueingRabbit.purge_queue(job)
      }

      done(4.0) {
        expect(@queue_size).to eq(100)
      }
    }
  end
  
end

