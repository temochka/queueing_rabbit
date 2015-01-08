require 'spec_helper'
require 'integration/jobs/print_line_job'

describe "Synchronous publishing and asynchronous consuming example" do
  include_context "Auto-disconnect"
  include_context "StringIO logger"

  let(:job) { PrintLineJob }
  let(:line) { "Hello, world!" }

  context "when a message is published and consumed synchronously" do
    
    let(:worker) { QueueingRabbit::Worker.new([job.to_s]) }
    let(:io) { StringIO.new }

    before do
      job.io = io
      job.enqueue(line)
    end

    specify do
      worker.work
      sleep 0.5
      io.string.should include(line)
    end

  end

end