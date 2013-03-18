require 'spec_helper'

describe QueueingRabbit::Client::AMQP do

  include_context "StringIO logger"

  let(:connection) { mock :on_tcp_connection_loss => nil, :on_recovery => nil }

  before do
    QueueingRabbit.stub(:amqp_uri => 'amqp://localhost:5672',
                        :amqp_exchange_name => 'queueing_rabbit_test',
                        :amqp_exchange_options => {:durable => true})
  end

  context "class" do
    subject { QueueingRabbit::Client::AMQP }

    its(:connection_options) { should include(:timeout) }
    its(:connection_options) { should include(:heartbeat) }
    its(:connection_options) { should include(:on_tcp_connection_failure) }

    describe '.run_event_machine' do
      context 'when the event machine reactor is running' do
        before do
          EM.should_receive(:reactor_running?).and_return(true)
        end

        it 'has no effect' do
          subject.run_event_machine
        end
      end

      context 'when the event machine reactor is not running' do
        before do
          EM.should_receive(:reactor_running?).and_return(false)
          Thread.should_receive(:new).and_yield
          EM.should_receive(:run).and_yield
        end

        it 'runs the event machine reactor in a separate thread' do
          subject.run_event_machine
        end

        it 'triggers :event_machine_started event' do
          QueueingRabbit.should_receive(:trigger_event)
                        .with(:event_machine_started)
          subject.run_event_machine
        end
      end
    end

    describe ".connect" do
      before do
        AMQP.should_receive(:connect).with(QueueingRabbit.amqp_uri)
                                     .and_return(connection)
        subject.should_receive(:run_event_machine)
      end

      it "creates a class' instance" do
        subject.connect.should be_instance_of(subject)
      end
    end

    describe '.join_event_machine_thread' do
      let(:thread) { mock(:join => true) }

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
      AMQP.stub(:connect => connection)
      QueueingRabbit::Client::AMQP.stub(:run_event_machine => true)
    end

    it_behaves_like :client

    it { should be }

    describe '#listen_queue' do
      let(:channel) { mock }
      let(:queue_name) { mock }
      let(:options) { mock }
      let(:queue) { mock }
      let(:metadata) { stub(:ack => true) }
      let(:data) { {:data => "data"}}
      let(:payload) { JSON.dump(data) }

      before do
        client.should_receive(:define_queue).with(channel, queue_name, options)
              .and_return(queue)
        queue.should_receive(:subscribe).with(:ack => true)
                                        .and_yield(metadata, payload)
      end

      it 'listens to the queue and passes deserialized arguments to the block' do
        client.listen_queue(channel, queue_name, options) do |arguments|
          arguments.should == data
        end
      end

      context "when deserialization problems occur" do
        let(:error) { JSON::JSONError.new }
        before do
          client.should_receive(:deserialize).and_raise(error)
          client.should_receive(:error)
          client.should_receive(:debug).with(error)
        end

        it "keeps the record of the errors" do
          client.listen_queue(channel, queue_name, options)
        end

        it "silences JSON errors" do
          expect { client.listen_queue(channel, queue_name, options) }
                 .to_not raise_error(error)
        end
      end
    end

    describe '#process_message' do
      let(:arguments) { mock }

      it "yields given arguments to the block" do
        client.process_message(arguments) do |a|
          a.should == arguments
        end
      end

      it "silences all errors risen" do
        expect { 
          client.process_message(arguments) { |a| raise StandardError.new }
        }.to_not raise_error(StandardError)
      end

      context "logging" do
        let(:error) { StandardError.new }
        before do
          client.should_receive(:error)
          client.should_receive(:debug).with(error)
        end

        it "keeps the record of all errors risen" do
          client.process_message(arguments) { |a| raise error }
        end
      end
    end

    describe '#disconnect' do
      before do
        subject.should_receive(:info)
        connection.should_receive(:close).and_yield
        EM.should_receive(:stop)
      end

      it 'writes the log, closes connection and stops the reactor' do
        client.disconnect
      end
    end

    describe "#open_channel" do
      let(:next_channel_id) { mock }
      let(:options) { mock }
      let(:channel) { mock }
      let(:open_ok) { mock }

      before do
        AMQP::Channel.should_receive(:next_channel_id)
                     .and_return(next_channel_id)
        AMQP::Channel.should_receive(:new)
                     .with(connection, next_channel_id, options)
                     .and_yield(channel, open_ok)
        channel.should_receive(:on_error)
      end

      it 'opens a new AMQP channel with given options and installs ' \
         'on-error callback' do
        client.open_channel(options) {}
      end
    end
  end
end