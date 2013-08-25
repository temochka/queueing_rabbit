require 'spec_helper'

describe QueueingRabbit::JobExtensions::NewRelic do
  let(:installation) {
    Proc.new do
      job.class_eval { include QueueingRabbit::JobExtensions::NewRelic }
    end
  }
  let(:new_relic) { Module.new }

  before do
    stub_const('NewRelic::Agent::Instrumentation::ControllerInstrumentation',
               new_relic)
  end

  context 'when is being installed into an instantiated job' do
    let(:job) { Class.new(QueueingRabbit::AbstractJob) }

    it 'registers a transaction tracer' do
      job.should_receive(:add_transaction_tracer).
          with(:perform, :category => :task)
      installation.call
    end
  end

  context 'when is being installed into a class based job' do
    let(:job) { Class.new { def self.perform; end } }

    it 'registers a transaction tracer' do
      job.class.should_receive(:add_transaction_tracer).
          with(:perform, :category => :task)
      installation.call
    end
  end
end