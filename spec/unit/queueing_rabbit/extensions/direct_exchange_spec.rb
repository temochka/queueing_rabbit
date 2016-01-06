require 'spec_helper'

describe QueueingRabbit::JobExtensions::DirectExchange do

  let(:test_job) {
    Class.new(QueueingRabbit::AbstractJob) do
      include QueueingRabbit::JobExtensions::DirectExchange

      exchange 'test_job'
      queue 'test_queue'
    end
  }

  subject { test_job }

  its(:exchange_name) { should == 'test_job' }
  its(:exchange_options) { should include(:type => :direct) }
  its(:binding_declarations) { should include(:routing_key => 'test_queue') }

  describe '#binding_declarations' do
    it 'is idempotent' do
      subject.binding_declarations.length.should eq(1)
      subject.binding_declarations.length.should eq(1)
    end
  end
end
