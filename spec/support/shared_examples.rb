shared_examples :client do

  describe '#define_exchange' do
    let(:channel) { mock }
    let(:options) { {:durable => true} }

    before do
      channel.should_receive(:direct).
              with(QueueingRabbit.amqp_exchange_name,
                   QueueingRabbit.amqp_exchange_options.merge(options))
    end

    it 'defines a new AMQP direct exchange with given name and options' do
      client.define_exchange(channel, options)
    end
  end

  describe '#enqueue' do
    let(:channel) { mock }
    let(:exchange) { mock }
    let(:routing_key) { :routing_key }
    let(:payload) { {"test" => "data"} }

    before do
      client.should_receive(:exchange).with(channel).and_return(exchange)
      exchange.should_receive(:publish).with(JSON.dump(payload),
                                             :key => routing_key.to_s,
                                             :persistent => true)
    end

    it "publishes a new persistent message to the used exchange with " \
       "serialized payload and routed using given routing key" do
      client.enqueue(channel, routing_key, payload)
    end
  end

end