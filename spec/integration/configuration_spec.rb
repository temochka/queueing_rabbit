require 'spec_helper'

describe 'Configuring jobs' do
  context 'when a job is inherited from a base class' do
    let(:base_class) {
      Class.new(QueueingRabbit::AbstractJob) do
        exchange 'exchange_name', :durable => true
        channel :prefetch => 15
        queue :durable => true
        bind :ack => true
        publishing_defaults :persistent => true
      end
    }

    let(:job_class) {
      Class.new(base_class) do
        queue 'queue_name'
      end
    }

    subject { job_class }

    its(:queue_name) { should == 'queue_name' }
    its(:exchange_name) { should == 'exchange_options' }
    its(:queue_options) { should include(:durable => true) }
    its(:binding_options) { should include(:ack => true) }
    its(:publishing_defaults) { should include(:persistent => true) }
    its(:channel_options) { should include(:prefetch => 15) }
  end
end