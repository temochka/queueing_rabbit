require 'celluloid'

module QueueingRabbit

  module JobExtensions

    class Monitor

      include Celluloid

      trap_exit :report_error

      def initialize
        @logger = QueueingRabbit.logger
      end

      def report_error(obj, e)
        return unless e
        @logger.error "unexpected error #{e.class} occured."
        @logger.debug e
      end

    end

    module Threaded

      def self.included(klass)
        klass.send(:include, Celluloid)
        klass.extend(ClassMethods)
      end

      def perform_and_terminate
        perform
        terminate
      end

      module ClassMethods

        def perform(payload, metadata)
          job = self.new(payload, metadata)
          monitor.link(job)
          job.async.perform_and_terminate
        end

        def monitor
          create_monitor unless Celluloid::Actor[monitor_name]
          Celluloid::Actor[monitor_name]
        end

        def create_monitor
          Monitor.supervise_as(monitor_name)
        end

        def monitor_name
          :queueing_rabbit_monitor
        end

      end

    end

  end

end