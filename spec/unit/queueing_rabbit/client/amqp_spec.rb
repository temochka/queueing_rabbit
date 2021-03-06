require 'spec_helper'

describe QueueingRabbit::Client::AMQP do

  include_context "StringIO logger"
  include_context "No existing connections"

  let(:connection) { double(:on_tcp_connection_loss => nil, :on_recovery => nil) }

  before do
    QueueingRabbit.stub(:amqp_uri => 'amqp://localhost:5672')
  end

  context "class" do
    subject { QueueingRabbit::Client::AMQP }

    its(:connection_options) { should include(:timeout) }
    its(:connection_options) { should include(:heartbeat) }
    its(:connection_options) { should include(:on_tcp_connection_failure) }

    describe '.ensure_event_machine_is_running' do
      context 'when the event machine reactor is running' do
        before do
          EM.should_receive(:reactor_running?).and_return(true)
        end

        it 'has no effect' do
          subject.ensure_event_machine_is_running
        end
      end

      context 'when the event machine reactor is not running' do
        before do
          EM.should_receive(:reactor_running?).once.and_return(false)
          EM.should_receive(:reactor_running?).and_return(true)
          Thread.should_receive(:new).and_yield
          EM.should_receive(:run).and_yield
        end

        it 'runs the event machine reactor in a separate thread' do
          subject.ensure_event_machine_is_running
        end

        it 'triggers :event_machine_started event' do
          QueueingRabbit.should_receive(:trigger_event).
                         with(:event_machine_started)
          subject.ensure_event_machine_is_running
        end
      end

      context 'when the event machine can reactor can not be started' do
        before do
          EM.should_receive(:reactor_running?).once.and_return(false)
          EM.should_receive(:reactor_running?).and_raise(Timeout::Error)
          Thread.should_receive(:new).and_yield
          EM.should_receive(:run).and_yield
        end

        it 'raises a QueueingRabbitError after 5 seconds expire' do
          expect { subject.ensure_event_machine_is_running }.
              to raise_error(QueueingRabbit::QueueingRabbitError)
        end
      end
    end

    describe ".connect" do
      before do
        AMQP.should_receive(:connect).
             with(QueueingRabbit.amqp_uri, subject.connection_options).
             and_return(connection)
        subject.should_receive(:run_event_machine)
      end

      it "creates a class' instance" do
        subject.connect.should be_instance_of(subject)
      end
    end

    describe '.join_event_machine_thread' do
      let(:thread) { double(:join => true) }

      before do
        subject.instance_variable_set(:@event_machine_thread, thread)
      end

      it "joins the thread if exists" do
        subject.join_event_machine_thread
      end
    end
  end

  context "instance" do
    let(:client) { QueueingRabbit::Client::AMQP.connect }
    subject { client }

    before do
      EM.stub(:reactor_running? => true)
      AMQP.stub(:connect => connection)
      QueueingRabbit::Client::AMQP.stub(:run_event_machine => true)
    end

    it { should be }

    describe '#define_queue' do
      let(:channel) { double }
      let(:queue) { double }
      let(:queue_name) { "test_queue_name" }
      let(:options) { {:durable => false} }

      before do
        channel.should_receive(:queue).with(queue_name, options).
                                       and_yield(queue)
      end

      it "defines a queue" do
        client.define_queue(channel, queue_name, options)
      end
    end

    describe '#listen_queue' do
      let(:options) { double }
      let(:queue) { double }
      let(:metadata) { double }
      let(:payload) { double }

      before do
        queue.should_receive(:subscribe).with(options).
                                         and_yield(metadata, payload)
      end

      it 'listens to the queue and passes deserialized arguments to the block' do
        client.listen_queue(queue, options) do |payload, metadata|
          payload.should == payload
          metadata.should == metadata
        end
      end
    end

    describe '#close' do
      before do
        subject.should_receive(:info)
        connection.should_receive(:disconnect).and_yield
        EM.should_receive(:stop)
      end

      it 'writes the log, closes connection and stops the reactor' do
        client.close
      end
    end

    describe "#open_channel" do
      let(:options) { {:use_publisher_confirms => true} }
      let(:channel) { double }
      let(:open_ok) { double }

      before do
        AMQP::Channel.should_receive(:new).
                      with(connection, nil, options).
                      and_yield(channel, open_ok)
        channel.should_receive(:on_error)
        channel.should_receive(:confirm_select)
      end

      it 'opens a new AMQP channel with given options and installs ' \
         'on-error callback' do
        client.open_channel(options) {}
      end
    end

    describe '#define_exchange' do
      context 'when only channel is given' do
        let(:channel) { double }
        let(:default_exchange) { double }

        before do
          channel.should_receive(:default_exchange).and_return(default_exchange)
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

    describe '#next_tick' do

      it 'schedules given action to be performed at the next EM tick' do
        EM.should_receive(:next_tick)
        client.next_tick {}
      end

    end

    describe '#purge_queue' do
      
      let(:queue) { double }

      it 'purges the queue and fires the provided callback when done' do
        queue.should_receive(:purge).and_yield
        expect { |b| client.purge_queue(queue, &b) }.to yield_control
      end

    end

  end
end