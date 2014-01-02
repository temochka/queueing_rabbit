module QueueingRabbit
  class Worker
    include QueueingRabbit::Logging

    attr_accessor :jobs

    def initialize(*jobs)
      self.jobs = jobs.map { |job| job.to_s.strip }

      sync_stdio
      validate_jobs
      constantize_jobs
    end

    def work
      conn = QueueingRabbit.connection
      trap_signals(conn)

      jobs.each { |job| run_job(conn, job) }

      QueueingRabbit.trigger_event(:consuming_started)
    end

    def work!
      QueueingRabbit.begin_worker_loop do
        work
      end
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
      QueueingRabbit.follow_job_requirements(job) do |_, _, queue|
        conn.listen_queue(queue, job.listening_options) do |payload, metadata|
          info "performing job #{job}"
          invoke_job(job, payload, metadata)
        end
      end
    end

    def invoke_job(job, payload, metadata)
      if job.respond_to?(:perform)
        job.perform(payload, metadata)
      elsif job <= QueueingRabbit::AbstractJob
        job.new(payload, metadata).perform
      else
        error "do not know how to perform job #{job}"
      end
    end

    def sync_stdio
      $stdout.sync = true
      $stderr.sync = true
    end

    def trap_signals(connection)
      handler = Proc.new do
        connection.close {
          QueueingRabbit.trigger_event(:consuming_done)
          remove_pidfile
        }
      end

      Signal.trap("TERM", &handler)
      Signal.trap("INT", &handler)
    end
  end
end