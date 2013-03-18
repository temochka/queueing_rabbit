require 'spec_helper'

describe QueueingRabbit::Configuration do
  subject { Class.new { extend QueueingRabbit::Configuration} }

  it { should respond_to(:amqp_uri) }
  it { should respond_to(:amqp_exchange_name) }
  it { should respond_to(:amqp_exchange_options) }
  it { should respond_to(:tcp_timeout) }
  it { should respond_to(:heartbeat) }
end