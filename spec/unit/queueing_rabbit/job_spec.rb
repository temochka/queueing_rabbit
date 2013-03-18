require 'spec_helper'

describe QueueingRabbit::AbstractJob do
  subject { QueueingRabbit::AbstractJob }
  
  it { should respond_to(:queue).with(2).arguments }
  it { should respond_to(:queue_name) }
  it { should respond_to(:queue_options) }
  it { should respond_to(:channel_options) }
  it { should respond_to(:channel).with(1).argument }

  its(:queue_name) { should == 'AbstractJob' }

  describe ".queue_size" do
    let(:size) { mock }

    before do
      QueueingRabbit.should_receive(:queue_size).with(subject).and_return(size)
    end

    its(:queue_size) { should == size }
  end
end