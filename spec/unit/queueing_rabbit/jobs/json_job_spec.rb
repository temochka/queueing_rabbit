require 'spec_helper'

describe QueueingRabbit::JSONJob do
  let(:json_job) { QueueingRabbit::JSONJob }
  let(:payload) { JSON.dump(:foo => 'bar') }
  let(:metadata) { mock }

  subject { json_job.new(payload, metadata) }

  its(:payload) { should include(:foo => 'bar') }

  describe '.enqueue' do
    let(:options) { {:persistent => true} }
    let(:result_options) { options.merge(:routing_key => 'JSONJob') }

    it 'dumps payload to JSON' do
      QueueingRabbit.should_receive(:enqueue).
                     with(json_job, payload, result_options)
      json_job.enqueue({:foo => 'bar'}, options)
    end
  end
end