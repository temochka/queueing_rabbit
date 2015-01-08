require 'spec_helper'

describe 'Terminating a worker' do
  include_context 'Auto-disconnect'
  include_context 'StringIO logger'
  
  let(:queue) { Queue.new }
  let(:job_name) { 'SleepAndAckJob' }
  let(:job) {
    Class.new(QueueingRabbit::AbstractJob) {
      queue 'sleep_and_ack'
      listen :manual_ack => true

      def self.complete!
        @complete = true
      end

      def self.complete?
        !!@complete
      end

      def perform
        sleep 3
        self.class.complete!
        acknowledge
      end
    }
  }
  let(:worker) { QueueingRabbit::Worker.new([job_name]) }

  before do
    QueueingRabbit.purge_queue(job)
    stub_const(job_name, job)
  end

  context 'when gracefully shut down' do
    it 'waits for currently running consumers' do
      worker.work
      job.enqueue('')
      sleep 1
      worker.stop(QueueingRabbit.connection, true)
      expect(job).to be_complete
    end
  end

  context 'when shut down immediately' do
    it 'terminates right away' do
      worker.work
      job.enqueue('')
      sleep 1
      worker.stop
      expect(job).to_not be_complete
    end
  end
end