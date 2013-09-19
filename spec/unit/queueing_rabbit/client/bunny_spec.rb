require 'spec_helper'

describe QueueingRabbit::Client::Bunny do
  let(:connection) { stub(:start => true) }

  before do
    QueueingRabbit.stub(:amqp_uri => 'amqp://localhost:5672')
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

    it { should be }

    describe '#open_channel' do
      let(:options) { {:use_publisher_confirms => true} }
      let(:channel) { mock }

      before do
        connection.should_receive(:create_channel).and_return(channel)
        channel.should_receive(:confirm_select)
      end

      it 'creates a channel and yields it' do
        client.open_channel(options) do |c, _|
          c.should == channel
        end
      end
    end

    describe '#define_queue' do
      let(:channel) { mock }
      let(:queue) { mock }
      let(:name) { 'queue_name_test' }
      let(:options) { {:foo => 'bar'} }

      it 'creates a queue and binds it to the global exchange' do
        channel.should_receive(:queue).with(name, options).and_return(queue)
        client.define_queue(channel, name, options).should == queue
      end

      context 'when block is given' do
        it 'yields the created queue' do
          channel.should_receive(:queue).with(name, options).and_return(queue)

          client.define_queue(channel, name, options) do |q|
            q.should == queue
          end
        end
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

    describe '#define_exchange' do
      context 'when only channel is given' do
        let(:channel) { mock }
        let(:default_exchange) { mock }

        before do
          channel.should_receive(:default_exchange).
                  and_return(default_exchange)
        end

        it 'returns the default exchange' do
          client.define_exchange(channel).should == default_exchange
        end
      end

      context 'with arguments and type' do
        let(:channel) { mock }
        let(:name) { 'some_exchange_name' }
        let(:options) { {:type => 'direct'} }
        let(:exchange) { mock }

        it 'creates an exchange of given type and options' do
          channel.should_receive(:direct).with(name, options).
                                          and_return(exchange)
          client.define_exchange(channel, name, options).should == exchange
        end
      end
    end

    describe '#enqueue' do
      let(:exchange) { mock }
      let(:payload) { mock }
      let(:options) { mock }

      it "publishes a new message to given exchange with given options" do
        exchange.should_receive(:publish).with(payload, options)
        client.enqueue(exchange, payload, options)
      end
    end

  end
end