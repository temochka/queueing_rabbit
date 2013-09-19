require 'spec_helper'

describe QueueingRabbit::AbstractBus do
  let(:bus_class) {
    Class.new(QueueingRabbit::AbstractBus) do
      exchange 'test_exchange', :durable => false
      publish_with :routing_key => 'test_queue'
    end
  }

  subject { bus_class }

  it { should respond_to(:exchange).with(1).argument }
  it { should respond_to(:exchange).with(2).arguments }
  it { should respond_to(:exchange_name) }
  it { should respond_to(:exchange_options) }
  it { should respond_to(:channel_options) }
  it { should respond_to(:channel).with(1).argument }
  it { should respond_to(:publishing_defaults) }

  its(:exchange_name) { should == 'test_exchange' }
  its(:exchange_options) { should include(:durable => false) }
  its(:publishing_defaults) { should include(:routing_key => 'test_queue') }
  
end