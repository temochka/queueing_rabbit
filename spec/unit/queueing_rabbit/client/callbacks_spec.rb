require 'spec_helper'

describe QueueingRabbit::Client::Callbacks do
  let!(:klass) { Class.new { extend QueueingRabbit::Client::Callbacks } }

  subject { klass }

  it { should respond_to(:define_callback).with(1).argument }
  it { should respond_to(:callback).with(1).argument }

  context 'when a callback is being defined' do
    let(:code_block) { Proc.new {} }

    before do
      subject.define_callback(:on_some_event, &code_block)
    end

    it 'saves a provided code block as a callback' do
      subject.callback(:on_some_event).should == code_block
    end
  end
end