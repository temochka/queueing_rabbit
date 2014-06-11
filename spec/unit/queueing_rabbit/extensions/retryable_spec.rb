require 'spec_helper'

describe QueueingRabbit::JobExtensions::Retryable do

  let(:test_job) {
    Class.new(QueueingRabbit::AbstractJob) do
      include QueueingRabbit::JobExtensions::Retryable

      exchange 'test_job'
      queue 'test_queue'

      def perform
      end
    end
  }
  let(:payload) { double }
  let(:headers) { {'qr_retries' => 2} }
  let(:metadata) { double(:headers => headers)}

  subject { test_job.new(payload, metadata) }

  its(:retries) { should == 2 }

  describe '#retry_upto' do
    it 'returns nil and does not retry if attempts exceeded' do
      subject.retry_upto(2).should_not be
    end

    it 'retries with increased number of attempts' do
      test_job.should_receive(:enqueue).
               with(payload, :headers => {'qr_retries' => 3}).and_return(true)
      subject.retry_upto(3).should be true
    end
  end

end