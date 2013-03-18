require 'spec_helper'

describe QueueingRabbit::Callbacks do
  let!(:klass) { Class.new { extend QueueingRabbit::Callbacks } }
  subject { klass }

  context 'when a single callback is set for an event' do
    let(:callback) { Proc.new {} }

    before do
      subject.setup_callback(:test, &callback)
    end

    it 'saves the callback internally' do
      subject.instance_variable_get(:@callbacks).should include(:test)
    end

    context 'and when an event is triggered' do
      before do
        callback.should_receive(:call)
      end

      it 'executes the registered callback' do
        subject.trigger_event(:test)
      end
    end
  end

  context 'when multiple callbacks are set for an event' do
    let(:callback_1) { Proc.new {} }
    let(:callback_2) { Proc.new {} }

    before do
      subject.setup_callback(:test, &callback_1)
      subject.setup_callback(:test, &callback_2)
    end

    it 'saves the callbacks internally' do
      subject.instance_variable_get(:@callbacks).should include(:test)
    end

    context 'and when an event is triggered' do
      before do
        callback_1.should_receive(:call)
        callback_2.should_receive(:call)
      end

      it 'executes all the registered callbacks' do
        subject.trigger_event(:test)
      end
    end
  end
end