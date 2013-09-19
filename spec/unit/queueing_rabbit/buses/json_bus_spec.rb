require 'spec_helper'

describe QueueingRabbit::JSONBus do
  let(:json_bus) { QueueingRabbit::JSONBus }
  let(:payload) { JSON.dump(:foo => 'bar') }

  describe '.publish' do
    let(:options) { {:persistent => true} }

    it 'dumps payload to JSON' do
      QueueingRabbit.should_receive(:publish).
                     with(json_bus, payload, options)
      json_bus.publish({:foo => 'bar'}, options)
    end
  end
end