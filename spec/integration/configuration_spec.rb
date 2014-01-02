require 'spec_helper'

describe 'Configuring jobs' do
  include_context "Auto-disconnect"
  
  context 'when a job is inherited from a base class' do
    let(:base_class) {
      Class.new(QueueingRabbit::AbstractJob) do
        exchange 'exchange_name', :durable => true
        channel :prefetch => 15
        queue :durable => true
        bind :routing_key => 'sunday'
        publish_with :persistent => true
      end
    }

    let(:job_class) {
      Class.new(base_class) do
        queue 'queue_name'
      end
    }

    subject { job_class }

    its(:queue_name) { should == 'queue_name' }
    its(:exchange_name) { should == 'exchange_name' }
    its(:queue_options) { should include(:durable => true) }
    its(:binding_declarations) { should include(:routing_key => 'sunday') }
    its(:publishing_defaults) { should include(:persistent => true) }
    its(:channel_options) { should include(:prefetch => 15) }
  end

  context 'when cascading attributes', :ruby => '1.8.7' do
    let(:base_class) {
      Class.new(QueueingRabbit::AbstractJob) do
        exchange 'exchange_name', :durable => true
        channel :prefetch => 15
        queue :durable => true
        bind :routing_key => 'sunday'
        publish_with :persistent => true
      end
    }

    let(:job_class) {
      Class.new(base_class) do
        channel :use_publisher_confirms => true
        queue 'queue_name', :durable => false
        bind :routing_key => 'monday'
      end
    }

    subject { job_class }

    its(:channel_options) { should include(:use_publisher_confirms => true,
                                           :prefetch => 15) }
    its(:queue_options) { should include(:durable => false) }
    its(:binding_declarations) { should include(:routing_key => 'sunday') and include(:routing_key => 'monday') }
    its(:publishing_defaults) { should include(:persistent => true) }

  end

  context 'when using an extension' do
    let(:job_class) {
      Class.new(QueueingRabbit::AbstractJob) do
        include QueueingRabbit::JobExtensions::DirectExchange
        queue 'queue_name'
        exchange 'exchange_name'
      end
    }

    subject { job_class }

    its(:exchange_name) { should == 'exchange_name' }
    its(:exchange_options) { should include(:type => :direct) }
    its(:binding_declarations) { should include(:routing_key => 'queue_name')}
  end
end