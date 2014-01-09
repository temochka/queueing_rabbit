# require 'queueing_rabbit/tasks'
# will give you the queueing_rabbit tasks

namespace :queueing_rabbit do
  task :setup

  desc "Start a queueing rabbit worker"
  task :work => :setup do
    require 'queueing_rabbit'

    jobs = (ENV['JOBS'] || ENV['JOB']).to_s.split(',')

    begin
      worker = QueueingRabbit::Worker.new(*jobs)
    rescue QueueingRabbit::JobNotPresentError, QueueingRabbit::JobNotFoundError
      abort "set JOB env var, e.g. $ JOB=ExportDataJob,CompressFileJob " \
            "rake queueing_rabbit:work"
    end

    if ENV['BACKGROUND']
      unless Process.respond_to?('daemon')
        abort "env var BACKGROUND is set, which requires ruby >= 1.9"
      end
      Process.daemon(true)
    end

    begin
      worker.use_pidfile(ENV['PIDFILE']) if ENV['PIDFILE']
      worker.work!
    rescue QueueingRabbit::Worker::WorkerError => e
      abort e.message
    end
  end
end
