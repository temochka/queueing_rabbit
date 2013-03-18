shared_examples :client do
  
  describe '#define_queue' do
    let(:exchange) { mock }
    let(:channel) { mock }
    let(:queue) { mock }
    let(:queue_name) { "test_queue_name" }
    let(:routing_keys) { [:test_job] }
    let(:options) { {:durable => false, :routing_keys => routing_keys} }

    before do
      client.stub(:exchange => exchange)
      channel.should_receive(:queue).with(queue_name, options)
                                    .and_yield(queue)
      queue.should_receive(:bind)
           .with(exchange, :routing_key => routing_keys.first.to_s).ordered
      queue.should_receive(:bind)
           .with(exchange, :routing_key => queue_name).ordered
    end

    it "defines a queue and binds it to its name and the given routing keys" do
      client.define_queue(channel, queue_name, options)
    end
  end

  describe '#define_exchange' do
    let(:channel) { mock }
    let(:options) { {:durable => true} }

    before do
      channel.should_receive(:direct)
             .with(QueueingRabbit.amqp_exchange_name,
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