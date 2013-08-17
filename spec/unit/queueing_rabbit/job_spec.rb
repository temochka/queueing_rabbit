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
  it { should respond_to(:publishing_defaults).with(1).argument }

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
    let(:metadata) { stub(headers: headers) }

    subject { job_class.new(payload, metadata) }

    its(:payload) { should == payload }
    its(:metadata) { should == metadata }
    its(:headers) { should == headers }

    it { should respond_to(:perform) }
  end
end

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

describe QueueingRabbit::JobExtensions::DirectExchange do
  let(:test_job) {
    Class.new(QueueingRabbit::AbstractJob) do
      include QueueingRabbit::JobExtensions::DirectExchange

      exchange 'test_job'
      queue 'test_queue'
    end
  }

  subject { test_job }

  its(:exchange_name) { should == 'test_job' }
  its(:exchange_options) { should include(:type => :direct) }
  its(:binding_options) { should include(:routing_key => 'test_queue') }
end

describe QueueingRabbit::JobExtensions::Retryable do
  let(:test_job) {
    Class.new(QueueingRabbit::AbstractJob) do
      include QueueingRabbit::JobExtensions::Retryable

      exchange 'test_job'
      queue 'test_queue'

      def perform
      end
    end
  }
  let(:payload) { mock }
  let(:headers) { {:qr_retries => 2} }
  let(:metadata) { mock(headers: headers)}

  subject { test_job.new(payload, metadata) }

  its(:retries) { should == 2 }

  describe '#retry_upto' do
    it 'returns nil and does not retry if attempts exceeded' do
      subject.retry_upto(2).should_not be
    end

    it 'retries with increased number of attempts' do
      test_job.should_receive(:enqueue).with(payload, headers: {:qr_retries => 3}).and_return(true)
      subject.retry_upto(3).should be_true
    end
  end

end