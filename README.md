# QueueingRabbit

QueueingRabbit is a Ruby library that provides a convenient object-oriented
syntax for managing background jobs with AMQP. All jobs' argumets are
serialized to JSON and transfered as AMQP message payloads. The library
implements amqp and bunny gems as adapters, making it possible to use
synchronous publishing and asynchronous consuming, which might be useful for
Rails apps running on non-EventMachine based application servers (i. e.
Passenger).

## Installation

Add this line to your application's Gemfile:

    gem 'queueing_rabbit'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queueing_rabbit

## Usage

QueueingRabbit is currently in RC1 and is not recommended for production use.

The docs are coming soon, currently you can check out the examples in
`spec/integration` dir.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
