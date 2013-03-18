module QueueingRabbit
  class Worker
    include QueueingRabbit::Logging

    attr_accessor :jobs

    def initialize(*jobs)
      self.jobs = jobs.map { |job| job.to_s.strip }

      sync_stdio
      validate_jobs
      constantize_jobs
      use_asynchronous_client
    end

    def work
      conn = QueueingRabbit.connection
      trap_signals(conn)

      jobs.each { |job| run_job(conn, job) }

      QueueingRabbit.trigger_event(:consuming_started)
    end

    def work!
      work
      QueueingRabbit::Client::AMQP.join_event_machine_thread
    end

    def use_pidfile(filename)
      File.open(@pidfile = filename, 'w') { |f| f << pid }
    end

    def remove_pidfile
      File.delete(@pidfile) if @pidfile && File.exists?(@pidfile)
    end

    def pid
      Process.pid
    end

    def to_s
      "PID=#{pid}, JOBS=#{jobs.join(',')}"
    end

  private

    def use_asynchronous_client
      QueueingRabbit.client = QueueingRabbit::Client::AMQP
    end

    def validate_jobs
      if jobs.nil? || jobs.empty?
        fatal "no jobs specified to work on."
        raise JobNotPresentError.new("No jobs specified to work on.")
      end
    end

    def constantize_jobs
      self.jobs = jobs.map do |job|
        begin
          Kernel.const_get(job)
        rescue NameError
          fatal "job #{job} doesn't exist."
          raise JobNotFoundError.new("Job #{job} doesn't exist.")
        end
      end
    end

    def run_job(conn, job)
      conn.open_channel(job.channel_options) do |channel, _|
        conn.listen_queue(channel, job.queue_name, job.queue_options) do |args|
          info "performing job #{job} with arguments #{args.inspect}"
          job.perform(args)
        end
      end
    end

    def sync_stdio
      $stdout.sync = true
      $stderr.sync = true
    end

    def trap_signals(connection)
      handler = Proc.new do
        connection.disconnect {
          QueueingRabbit.trigger_event(:consuming_done)
          remove_pidfile
        }
      end

      Signal.trap("TERM", &handler)
      Signal.trap("INT", &handler)
    end
  end
end