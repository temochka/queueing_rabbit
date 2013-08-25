# -*- encoding: utf-8 -*-
require File.expand_path('../lib/queueing_rabbit/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Artem Chistyakov"]
  gem.email         = ["chistyakov.artem@gmail.com"]
  gem.summary       = %q{QueueingRabbit is an AMQP-based queueing system}
  gem.homepage      = "https://github.com/temochka/queueing_rabbit"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "queueing_rabbit"
  gem.require_paths = ["lib"]
  gem.version       = QueueingRabbit::VERSION

  gem.extra_rdoc_files  = [ "LICENSE", "README.md" ]
  gem.rdoc_options      = ["--charset=UTF-8"]

  gem.add_dependency "amqp",  "~> 1.0.0"
  gem.add_dependency "bunny", "~> 0.10.0"
  gem.add_dependency "rake",  ">= 0"
  gem.add_dependency "json",  ">= 0"

  gem.description   = <<description
    QueueingRabbit is a Ruby library providing convenient object-oriented syntax
    for managing background jobs using AMQP. The library implements amqp and
    bunny gems as adapters making it possible to use synchronous publishing and
    asynchronous consuming, which might be useful for Rails app running on
    non-EventMachine based application servers (i. e. Passenger).

    Any Ruby class or Module can be transformed into QueueingRabbit's background
    job by including QueueingRabbit::Job module. It is also possible to inherit
    your class from QueueingRabbit::AbstractJob abstract class.

    The library is bundled with a Rake task which is capable of starting a
    worker processing a specified list of jobs.
description
end
