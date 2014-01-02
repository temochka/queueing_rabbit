require 'spec_helper'

if RUBY_VERSION != '1.8.7'
  require 'queueing_rabbit/extensions/threaded'
else
  class QueueingRabbit::JobExtensions::Threaded; end
end

describe QueueingRabbit::JobExtensions::Threaded, :ruby => '1.8.7'  do

  let(:test_job) {
    Class.new(QueueingRabbit::AbstractJob) do

      include QueueingRabbit::JobExtensions::Threaded

      exchange 'test_job'
      queue 'test_queue'

      def perform
      end

    end
  }

  before do
    Celluloid.logger = nil
  end

  context 'new class methods' do
    subject { test_job }

    it { should respond_to(:perform).with(2).arguments }
    it { should respond_to(:monitor) }
  end

  context 'new instance methods' do
    subject { test_job.new(mock, mock) }

    it { should respond_to(:perform_and_terminate) }
  end

end