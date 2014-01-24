module QueueingRabbit
  class Worker

    class WorkerError < RuntimeError; end

    include QueueingRabbit::Logging

    attr_accessor :jobs

    def initialize(*jobs)
      self.jobs = jobs.map { |job| job.to_s.strip }

      sync_stdio
      validate_jobs
      constantize_jobs
    end

    def work
      trap_signals

      QueueingRabbit.trigger_event(:worker_ready)

      jobs.each { |job| run_job(QueueingRabbit.connection, job) }

      QueueingRabbit.trigger_event(:consuming_started)
    end

    def work!
      info "starting a new queueing_rabbit worker #{self}"

      QueueingRabbit.begin_worker_loop { work }
    end

    def use_pidfile(filename)
      @pidfile = filename
      cleanup_pidfile
      File.open(@pidfile, 'w') { |f| f << pid }
    end

    def remove_pidfile
      File.delete(@pidfile) if pidfile_exists?
    end

    def read_pidfile
      File.read(@pidfile).to_i if pidfile_exists?
    end

    def pidfile_exists?
      @pidfile && File.exists?(@pidfile)
    end

    def pid
      Process.pid
    end

    def to_s
      "PID=#{pid}, JOBS=#{jobs.join(',')}"
    end

    def stop
      connection = QueueingRabbit.connection

      connection.next_tick do
        connection.close do
          info "gracefully shutting down the worker #{self}"
          remove_pidfile
          QueueingRabbit.trigger_event(:consuming_done)
        end
      end
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
        error "don't know how to perform job #{job}"
      end
    end

    def sync_stdio
      $stdout.sync = true
      $stderr.sync = true
    end

    def trap_signals
      Signal.trap("TERM") { stop }
      Signal.trap("INT") { stop }
    end

    def cleanup_pidfile
      return unless pid_in_file = read_pidfile
      Process.getpgid(pid_in_file)
      fatal "failed to use the pidfile #{@pidfile}. It is already " \
            "in use by a process with pid=#{pid_in_file}."
      raise WorkerError.new('The pidfile is already in use.')
    rescue Errno::ESRCH
      info "found abandoned pidfile: #{@pidfile}. Can be safely overwritten."
    end

  end
end