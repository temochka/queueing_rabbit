$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'
Bundler.setup(:test)

require 'rspec'
require 'rspec/autorun'
require 'evented-spec'
require 'support/shared_contexts'

require 'queueing_rabbit'

RSpec.configure do |config|
  config.before(:each) {
    QueueingRabbit.drop_connection
  }

  QueueingRabbit.configure do |qr|
    qr.amqp_uri = "amqp://guest:guest@localhost:5672"
    qr.amqp_exchange_name = "queueing_rabbit_test"
    qr.amqp_exchange_options = {:durable => true}
  end
end
