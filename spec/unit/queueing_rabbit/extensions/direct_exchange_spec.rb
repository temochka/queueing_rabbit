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
  its(:binding_options) { should include(:routing_key => 'test_queue') }

end