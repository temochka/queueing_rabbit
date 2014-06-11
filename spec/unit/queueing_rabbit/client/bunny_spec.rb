require 'spec_helper'

describe QueueingRabbit::Client::Bunny do

  include_context "No existing connections"

  let(:connection) { double(:start => true) }

  before do
    allow(QueueingRabbit).to receive(:amqp_uri).and_return('amqp://localhost:5672')
  end

  context 'class' do
    subject { QueueingRabbit::Client::Bunny }

    describe '.connect' do
      before do
        Bunny.should_receive(:new).with(QueueingRabbit.amqp_uri, kind_of(Hash)).
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
      let(:options) { {:use_publisher_confirms => true, :prefetch => 42} }
      let(:channel) { double }

      before do
        connection.should_receive(:create_channel).and_return(channel)
        channel.should_receive(:confirm_select)
        channel.should_receive(:prefetch).with(42)
      end

      it 'creates a channel and yields it' do
        client.open_channel(options) do |c, _|
          c.should == channel
        end
      end
    end

    describe '#define_queue' do
      let(:channel) { double }
      let(:queue) { double }
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
      let(:queue) { double }
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
        let(:channel) { double }
        let(:default_exchange) { double }

        before do
          channel.should_receive(:default_exchange).
                  and_return(default_exchange)
        end

        it 'returns the default exchange' do
          client.define_exchange(channel).should == default_exchange
        end
      end

      context 'with arguments and type' do
        let(:channel) { double }
        let(:name) { 'some_exchange_name' }
        let(:options) { {:type => 'direct', :durable => true} }
        let(:exchange) { double }

        it 'creates an exchange of given type and options' do
          channel.should_receive(:direct).with(name, :durable => true).
                                          and_return(exchange)
          client.define_exchange(channel, name, options).should == exchange
        end
      end
    end

    describe '#enqueue' do
      let(:exchange) { double }
      let(:payload) { double }
      let(:options) { double }

      it "publishes a new message to given exchange with given options" do
        exchange.should_receive(:publish).with(payload, options)
        client.enqueue(exchange, payload, options)
      end
    end

    describe '#close' do

      before do
        connection.should_receive(:close)
      end

      it 'closes the connection and yields a block if given' do
        expect { |b| client.close(&b) }.to yield_control
      end

      it 'discontinues the worker loop' do
        expect { |b| client.close(&b) }.
            to change{client.instance_variable_get(:@continue_worker_loop)}.
               to(false)
      end

    end

    describe '#purge_queue' do

      let(:queue) { double }

      it 'purges the queue and fires the provided callback when done' do
        queue.should_receive(:purge)
        expect { |b| client.purge_queue(queue, &b) }.to yield_control
      end

    end

    describe '#next_tick' do

      context 'given the worker loop is running' do

        it 'performs the action on next tick' do
          client.connection.should_receive(:close)
          Thread.new { sleep 1; client.next_tick { client.close } }
          expect { Timeout.timeout(5) { client.begin_worker_loop } }.
              not_to raise_error { |e| expect(e).to be_a(Timeout::Error) }
        end

      end

      context 'given the worker loop is not running' do

        it 'performs the action immediately' do
          expect(client.next_tick { 42 }).to eq(42)
        end

      end

    end

  end
end