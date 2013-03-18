require 'spec_helper'

describe QueueingRabbit::Logging do
  subject { Class.new { extend QueueingRabbit::Logging } }

  %w[fatal error warn info debug].each do |level|
    it { should respond_to(level).with(1).argument }
  end
end