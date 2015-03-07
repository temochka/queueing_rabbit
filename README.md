# QueueingRabbit [![Build Status](https://travis-ci.org/temochka/queueing_rabbit.png?branch=master)](https://travis-ci.org/temochka/queueing_rabbit) [![Code Climate](https://codeclimate.com/github/temochka/queueing_rabbit.png)](https://codeclimate.com/github/temochka/queueing_rabbit)

QueueingRabbit provides a Ruby DSL to interact with RabbitMQ. It is fairly flexible and allows you to integrate with existing infrastructure and naming conventions. It currently offers gems [bunny](https://github.com/ruby-amqp/bunny) and [amqp](https://github.com/ruby-amqp/amqp) as supported back-ends.

## Disclaimer

I built this gem at [Wildbit](http://wildbit.com) in 2012. Back then there weren’t any solid generic queueing systems targeting RabbitMQ for Ruby. The gem was open-sourced in early 2013, but I never put any effort into selling it to the community. Even though the gem is working, maintained, and is still used by Wildbit in production, in the long run you should be better with now-existing mainstream alternatives like [hutch](https://github.com/gocardless/hutch) and [sneakers](https://github.com/jondot/sneakers).

## Example

The following Ruby program publishes an excerpt of Joseph Brodsky’s poem line by line to a RabbitMQ exchange and prints received messages on the screen.

``` ruby
require 'queueing_rabbit'

class Reciter < QueueingRabbit::AbstractJob

  def perform
    puts payload
  end

end

worker = QueueingRabbit::Worker.new(Reciter)

poem = <<-
  I said fate plays a game without a score,
  and who needs fish if you've got caviar?
  The triumph of the Gothic style would come to pass
  and turn you on - no need for coke, or grass.
  I sit by the window. Outside, an aspen.
  When I loved, I loved deeply. It wasn't often.


Thread.new {
  poem.each_line { |l| Reciter.enqueue(l) }
  sleep 5
  worker.stop
}

worker.work!
```

This code has following important side effects:

* A Rabbit queue named `Reciter` is created with default options (if not exists).
* 6 messages are published to the default exchange with routing key `Reciter`.
* 6 messages are consumed from the `Reciter` queue.
* 6 lines of the poem are printed to STDOUT.

## Choosing the back-end: bunny or amqp?

`Bunny` is a pseudo-synchronous RabbitMQ client. `Amqp` is EventMachine-based and heavily asynchronous (lots of callbacks involved). Both clients are in active development, thoroughly documented and fairly stable.

Choose `bunny` if you don’t want to worry about blocking I/O and EventMachine-compilant drivers. Choose `amqp` if you’re familiar with EventMachine, designing a lightweight app from scratch and performance is a serious concern. Obviously there are exceptions, and no one knows your requirements better than you.

Also, you can use both of them. For example, you may decide to publish via `bunny` from your Rails app and use `amqp` in your background worker.

## Documentation & Support

Check out the [project wiki](https://github.com/temochka/queueing_rabbit/wiki) for additional guidance. If you have questions or something doesn’t work for you, feel free to file issues.

## Installation

QueueingRabbit supports MRI Ruby version 1.9.3 and above. It is still compilant with Ruby 1.8.7, but some features may not work as expected and the compatibility will be removed in the near future.

Add this line to your application's `Gemfile`:

    gem 'queueing_rabbit'

And then execute:

    $ bundle

Or install it globally as:

    $ gem install queueing_rabbit


## Special Thanks

* [Wildbit](http://wildbit.com) — for letting me open source this library initially developed for the internal use.
* [RabbitMQ client libraries for Ruby](https://github.com/ruby-amqp) — for providing outstanding well-documented gems that made this project possible.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
