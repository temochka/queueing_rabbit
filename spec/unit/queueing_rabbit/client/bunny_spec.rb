require 'spec_helper'

describe QueueingRabbit::Client::Bunny do
  let(:connection) { stub(:start => true) }

  before do
    QueueingRabbit.stub(:amqp_uri => 'amqp://localhost:5672',
                        :amqp_exchange_name => 'queueing_rabbit_test',
                        :amqp_exchange_options => {:durable => true})
  end

  context 'class' do
    subject { QueueingRabbit::Client::Bunny }

    describe '.connect' do
      before do
        Bunny.should_receive(:new).with(QueueingRabbit.amqp_uri).
                                   and_return(connection)
      end

      it "instantiates an instance of itself" do
        subject.connect.should be_kind_of(subject)
      end
    end
  end

  context 'instance' do
    let(:client) { QueueingRabbit::Client::Bunny.connect }
    subject { client }

    before do
      Bunny.stub(:new => connection)
    end

    it_behaves_like :client

    it { should be }

    describe '#open_channel' do
      let(:options) { mock }
      let(:channel) { mock }

      before do
        connection.should_receive(:create_channel).and_return(channel)
      end

      it 'creates a channel and yields it' do
        client.open_channel do |c, _|
          c.should == channel
        end
      end
    end

    describe '#define_queue' do
      let(:channel) { mock }
      let(:queue) { mock }
      let(:exchange) { mock }
      let(:name) { 'queue_name_test' }
      let(:options) { {:foo => 'bar'} }

      it 'creates a queue and binds it to the global exchange' do
        channel.should_receive(:queue).with(name, options).and_return(queue)
        client.should_receive(:exchange).with(channel).and_return(exchange)
        queue.should_receive(:bind).with(exchange, :routing_key => name)

        client.define_queue(channel, name, options)
      end
    end

    describe '#queue_size' do
      let(:queue) { mock }
      let(:status) { {:message_count => 42} }

      before do
        queue.should_receive(:status).and_return(status)
      end

      it "returns a number of messages in queue" do
        client.queue_size(queue).should be_a(Fixnum)
      end
    end

  end
end