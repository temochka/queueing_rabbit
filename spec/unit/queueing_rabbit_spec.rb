require 'spec_helper'

describe QueueingRabbit do
  include_context "StringIO logger"

  let(:connection) { mock }
  let(:queue_name) { mock }
  let(:queue_options) { { :durable => true} }
  let(:channel) { mock }
  let(:channel_options) { { :prefetch => 1, :auto_recovery => true } }
  let(:job) do
    qname, qopts, copts = queue_name, queue_options, channel_options
    Class.new do
      extend QueueingRabbit::Job
      queue qname, qopts
      channel copts
    end
  end

  before(:each) { subject.drop_connection }

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
  end

  describe ".enqueue" do
    let(:arguments) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
      connection.should_receive(:open_channel).with(channel_options)
                .and_yield(channel, nil)
      connection.should_receive(:define_queue).with(channel,
                                                    queue_name,
                                                    queue_options)
      connection.should_receive(:enqueue).with(channel,
                                               queue_name, arguments)
    end

    it 'returns true when a message was enqueued successfully' do
      subject.enqueue(job, arguments).should be_true
    end

    context 'logging' do
      before do
        subject.should_receive(:info).and_return(nil)
      end

      it 'keeps the record of enqueued job at info level' do
        subject.enqueue(job, arguments).should be_true
      end
    end
  end

  describe ".queue_size" do
    let(:size) { mock }
    let(:queue) { mock }

    before do
      subject.instance_variable_set(:@connection, connection)
      connection.should_receive(:open_channel).with(channel_options)
                .and_yield(channel, nil)
      connection.should_receive(:define_queue).with(channel,
                                                    queue_name,
                                                    queue_options)
                                              .and_return(queue)
      connection.should_receive(:queue_size).with(queue).and_return(size)
    end

    it 'returns queue size for specific job' do
      subject.queue_size(job).should == size
    end
  end
end