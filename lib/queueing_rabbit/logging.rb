require "logger"

module QueueingRabbit

  module Logging

    # Logging levels are defined at:
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html
    %w[fatal error warn info debug].each do |level|
      define_method(level) do |message|
        QueueingRabbit.logger.__send__(level, message) if QueueingRabbit.logger
      end
    end

  end

end