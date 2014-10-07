require 'monitor'

module QueueingRabbit
  class Worker

    class WorkerError < RuntimeError; end

    include QueueingRabbit::Logging

    attr_accessor :jobs

    def initialize(*jobs)
      self.jobs = jobs.map { |job| job.to_s.strip }

      @messages_lock = Monitor.new
      @messages = {}

      sync_stdio
      validate_jobs
      constantize_jobs
    end

    def checked_messages_count
      @messages_lock.synchronize do
        @messages.count
      end
    end

    def checkin_message(delivery_tag)
      return unless @working

      @messages_lock.synchronize do
        @messages[delivery_tag] = true
      end
    end

    def checkout_message(delivery_tag)
      @messages_lock.synchronize do
        @messages.delete(delivery_tag)
      end
    end

    def working?
      @working
    end

    def work
      return if working?

      @working = true
      @channels = []

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
      "PID=#{pid}, JOBS=#{jobs.join(',')}"
    end

    def stop(connection = QueueingRabbit.connection)
      connection.next_tick do
        @working = false
        close_channels do
          connection.close do
            info "gracefully shutting down the worker #{self}"
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

    def close_channels(connection = QueueingRabbit.connection)
      connection.wait_while_for(Proc.new { checked_messages_count > 0 },
                                QueueingRabbit.jobs_wait_timeout) do
        @channels.each(&:close)
        QueueingRabbit.trigger_event(:consuming_done)
        yield
      end
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
      QueueingRabbit.follow_job_requirements(job) do |ch, _, queue|
        @channels << ch
        conn.listen_queue(queue, job.listening_options) do |payload, metadata|
          if checkin_message(metadata.object_id)
            invoke_job(job, payload, metadata)
            checkout_message(metadata.object_id)
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
      Signal.trap("TERM") { stop(connection) }
      Signal.trap("INT") { stop(connection) }
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