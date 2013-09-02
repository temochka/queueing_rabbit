require 'spec_helper'

describe QueueingRabbit::AbstractJob do
  let(:job_class) {
    Class.new(QueueingRabbit::AbstractJob) do
      queue 'test_queue', :durable => true
      exchange 'test_exchange', :durable => false
      bind :routing_key => 'test.*'
    end
  }

  subject { job_class }

  it { should respond_to(:exchange).with(1).argument }
  it { should respond_to(:exchange).with(2).arguments }
  it { should respond_to(:exchange_name) }
  it { should respond_to(:exchange_options) }
  it { should respond_to(:queue).with(1).argument }
  it { should respond_to(:queue).with(2).arguments }
  it { should respond_to(:queue_name) }
  it { should respond_to(:queue_options) }
  it { should respond_to(:channel_options) }
  it { should respond_to(:channel).with(1).argument }
  it { should respond_to(:enqueue).with(1).argument }
  it { should respond_to(:enqueue).with(2).arguments }
  it { should respond_to(:listening_options) }
  it { should respond_to(:listen) }
  it { should respond_to(:listen).with(1).argument }
  it { should respond_to(:publishing_defaults) }

  its(:queue_name) { should == 'test_queue' }
  its(:queue_options) { should include(:durable => true) }
  its(:exchange_options) { should include(:durable => false) }
  its(:binding_options) { should include(:routing_key => 'test.*') }
  its(:publishing_defaults) { should include(:routing_key => 'test_queue') }

  describe ".queue_size" do
    let(:size) { mock }

    before do
      QueueingRabbit.should_receive(:queue_size).with(subject).and_return(size)
    end

    its(:queue_size) { should == size }
  end

  describe '.enqueue' do
    let(:payload) { mock }
    let(:options) { {:persistent => true} }
    let(:result_options) { options.merge(job_class.publishing_defaults) }

    it 'enqueues a job of its own type with given argument' do
      QueueingRabbit.should_receive(:enqueue).
                     with(subject, payload, result_options)
      subject.enqueue(payload, options)
    end
  end

  context 'instance methods' do
    let(:payload) { mock }
    let(:headers) { mock }
    let(:metadata) { stub(:headers => headers) }

    subject { job_class.new(payload, metadata) }

    its(:payload) { should == payload }
    its(:metadata) { should == metadata }
    its(:headers) { should == headers }

    it { should respond_to(:perform) }
  end
end