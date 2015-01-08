require "queueing_rabbit/misc/mutex_pool"

module QueueingRabbit
  class Worker

    class WorkerError < RuntimeError; end

    include QueueingRabbit::Logging

    attr_reader :jobs, :concurrency, :mutex_pool

    def initialize(jobs, concurrency = nil)
      @jobs = jobs.map { |job| job.to_s.strip }.reject { |job| job.empty? }
      @concurrency = concurrency || @jobs.count
      @mutex_pool = ::MutexPool.new(@concurrency)

      sync_stdio
      validate_jobs
      constantize_jobs
    end

    def working?
      @working
    end

    def work
      return if working?
      @working = true

      QueueingRabbit.trigger_event(:worker_ready)
      jobs.each { |job| run_job(QueueingRabbit.connection, job) }
      QueueingRabbit.trigger_event(:consuming_started)
    end

    def work!
      return if working?

      trap_signals
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
      "PID=#{pid}, JOBS=#{jobs.join(',')} CONCURRENCY=#{@concurrency}"
    end

    def stop(connection = QueueingRabbit.connection, graceful = false)
      connection.next_tick do
        begin
          @working = false
          if graceful
            Timeout.timeout(QueueingRabbit.jobs_wait_timeout) { @mutex_pool.lock }
            QueueingRabbit.trigger_event(:consuming_done)
            info "gracefully shutting down the worker #{self}"
          end
        rescue Timeout::Error
          error "a timeout (> #{QueueingRabbit.jobs_wait_timeout}s) when trying to gracefully shut down the worker " \
                "#{self}"
        rescue => e
          error "a #{e.class} error occurred when trying to shut down the worker #{self}"
          debug e
        ensure
          connection.close do
            remove_pidfile
          end
        end
      end
    end

    def invoke_job(job, payload, metadata)
      info "performing job #{job}"
      
      if job.respond_to?(:perform)
        job.perform(payload, metadata)
      elsif job <= QueueingRabbit::AbstractJob
        job.new(payload, metadata).perform
      else
        error "don't know how to perform job #{job}"
      end
    rescue => e
      QueueingRabbit.trigger_event(:consumer_error, e)
      error "unexpected error #{e.class} occured: #{e.message}"
      debug e
    end

  private

    def validate_jobs
      if @jobs.nil? || @jobs.empty?
        fatal "no jobs specified to work on."
        raise JobNotPresentError.new("No jobs specified to work on.")
      end
    end

    def constantize_jobs
      @jobs = @jobs.map do |job|
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
          @mutex_pool.synchronize do
            invoke_job(job, payload, metadata)
          end
        end
      end
    end

    def sync_stdio
      $stdout.sync = true
      $stderr.sync = true
    end

    def trap_signals
      connection = QueueingRabbit.connection
      Signal.trap('QUIT') { stop(connection, true) }
      Signal.trap('TERM') { stop(connection) }
      Signal.trap('INT') { stop(connection) }
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