require 'spec_helper'

describe QueueingRabbit do
  include_context "No existing connections"
  include_context "StringIO logger"

  let(:connection) { mock }
  let(:queue_name) { mock }
  let(:queue_options) { {:durable => true} }
  let(:channel) { mock }
  let(:channel_options) { {:prefetch => 1, :auto_recovery => true} }
  let(:exchange_name) { mock }
  let(:exchange_options) { {:type => :direct, :durable => true} }
  let(:binding_declaration_1) { {:routing_key => 'routing_key'} }
  let(:binding_declaration_2) { {:routing_key => 'routing_key2'} }
  let(:job) {
    stub(:queue_name => queue_name,
         :queue_options => queue_options,
         :channel_options => channel_options,
         :exchange_name => exchange_name,
         :exchange_options => exchange_options,
         :binding_declarations => [binding_declaration_1, 
                                   binding_declaration_2],
         :bind_queue? => true)
  }

  it { should respond_to(:logger) }
  it { should respond_to(:client) }

  its(:logger) { should be_kind_of(Logger) }
  its(:client) { should be(QueueingRabbit::Client::Bunny) }

  describe ".connect" do
    before do
      subject.client.should_receive(:connect).and_return(connection)
      subject.connect
    end

    its(:connect) { should == connection }
    its(:connection) { should == connection }
    its(:conn) { should == connection }
  end

  describe ".enqueue" do
    let(:payload) { mock(:to_s => 'payload') }
    let(:options) { mock }
    let(:exchange) { mock }
    let(:channel) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
      subject.should_receive(:follow_job_requirements).
              with(job).
              and_yield(channel, exchange, nil)
      connection.should_receive(:publish).with(exchange, payload, options)
      channel.should_receive(:close)
    end

    it 'returns true when a message was enqueued successfully' do
      subject.enqueue(job, payload, options).should be_true
    end

    it 'keeps the record of enqueued job at info level' do
      subject.should_receive(:info).and_return(nil)
      subject.enqueue(job, payload, options).should be_true
    end
  end

  describe '.publish' do

    let(:bus) { QueueingRabbit::AbstractBus }
    let(:payload) { mock(:to_s => 'payload') }
    let(:options) { mock }
    let(:exchange) { mock }
    let(:channel) { mock }

    it 'publishes payload to a given bus with options' do
      subject.instance_variable_set(:@connection, connection)
      subject.should_receive(:follow_bus_requirements).
              with(bus).
              and_yield(channel, exchange)
      connection.should_receive(:publish).with(exchange, payload, options)
      channel.should_receive(:close)
      subject.publish(bus, payload, options).should be_true
    end

  end

  describe '.publish_to_exchange' do

    let(:exchange) { mock }
    let(:payload) { mock }
    let(:options) { mock }

    it 'publishes payload to a given exchange with options' do
      subject.instance_variable_set(:@connection, connection)
      connection.should_receive(:publish).with(exchange, payload, options)
      subject.publish_to_exchange(exchange, payload, options).should be_true
    end

  end

  describe '.begin_worker_loop' do

    before do
      subject.instance_variable_set(:@connection, connection)
    end

    it 'begins the worker loop on opened connection' do
      connection.should_receive(:begin_worker_loop).and_yield
      expect { |b| subject.begin_worker_loop(&b) }.to yield_control
    end

  end

  describe '.follow_job_requirements' do
    let(:channel) { mock }
    let(:exchange) { mock }
    let(:queue) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
    end

    it 'follows bus requirements, creates a queue, binds the queue to ' \
       'the exchange and yields' do
      subject.should_receive(:follow_bus_requirements).
              with(job).
              and_yield(channel, exchange)
      connection.should_receive(:define_queue).
                 with(channel, job.queue_name, job.queue_options).
                 and_yield(queue)
      connection.should_receive(:bind_queue).
                 with(queue, exchange, binding_declaration_1)
      connection.should_receive(:bind_queue).
                 with(queue, exchange, binding_declaration_2)

      subject.follow_job_requirements(job) do |ch, ex, q|
        ch.should == channel
        ex.should == exchange
        q.should == q
      end
    end
  end

  describe '.follow_bus_requirements' do
    let(:channel) { mock }
    let(:exchange) { mock }
    let(:bus) {
      stub(:channel_options => channel_options,
           :exchange_name => exchange_name,
           :exchange_options => exchange_options)
    }

    before do
      subject.instance_variable_set(:@connection, connection)
    end

    it 'opens a channel, defines an exchange and yields' do
      connection.should_receive(:open_channel).with(bus.channel_options).
                                        and_yield(channel, nil)
      connection.should_receive(:define_exchange).
                 with(channel, bus.exchange_name, bus.exchange_options).
                 and_yield(exchange)

      subject.follow_bus_requirements(bus) do |ch, ex|
        ch.should == channel
        ex.should == exchange
      end
    end
  end

  describe ".queue_size" do
    let(:size) { mock }
    let(:queue) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
      connection.should_receive(:open_channel).with(channel_options).
                 and_yield(channel, nil)
      connection.should_receive(:define_queue).
                 with(channel, queue_name, queue_options).
                 and_return(queue)
      connection.should_receive(:queue_size).with(queue).and_return(size)
      channel.should_receive(:close)
    end

    it 'returns queue size for specific job' do
      subject.queue_size(job).should == size
    end
  end

  describe ".purge_queue" do
    let(:queue) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
      connection.should_receive(:open_channel).
                 with(channel_options).and_yield(channel, nil)
      connection.should_receive(:define_queue).
                 with(channel, queue_name, queue_options).
                 and_yield(queue)
      connection.should_receive(:purge_queue).and_yield
      channel.should_receive(:close)
    end

    it 'purges messages from the queue' do
      subject.purge_queue(job).should be_true
    end
  end

end