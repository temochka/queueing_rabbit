require 'spec_helper'

describe QueueingRabbit::Configuration do
  subject { Class.new { extend QueueingRabbit::Configuration} }

  it { should respond_to(:amqp_uri) }
  it { should respond_to(:amqp_exchange_name) }
  it { should respond_to(:amqp_exchange_options) }

  its(:tcp_timeout) { should == 1 }
  its(:heartbeat) { should == 10 }
  its(:default_client) { should == QueueingRabbit::Client::Bunny }

  describe "#configure" do
    it "yields itself to the block" do
      subject.configure { |obj| obj.should == subject }
    end
  end
end