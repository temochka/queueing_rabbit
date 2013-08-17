require 'spec_helper'

describe QueueingRabbit::Worker do
  include_context "StringIO logger"

  subject { QueueingRabbit::Worker }
  let(:class_based_job) {
    Class.new(QueueingRabbit::AbstractJob) do
      def self.perform(payload, metadata); end
    end
  }
  let(:instance_based_job) { Class.new(QueueingRabbit::AbstractJob) }
  let(:creation) {
    Proc.new do
      QueueingRabbit::Worker.new('QueueingRabbitClassJob', QueueingRabbitInstanceJob)
    end
  }
  let(:worker) { creation.call }

  before do
    stub_const("QueueingRabbitClassJob", class_based_job)
    stub_const("QueueingRabbitInstanceJob", instance_based_job)
  end

  after(:each) do
    QueueingRabbit.client = QueueingRabbit::Client::Bunny
  end

  context 'initialization' do
    context 'when no jobs are provided' do
      before do
        subject.any_instance.should_receive(:fatal)
      end

      it 'raises JobNotPresentError' do
        expect { subject.new() }.
               to raise_error(QueueingRabbit::JobNotPresentError)
      end
    end

    context 'when nonexistent job is provided' do
      let(:nonexistent_class_name) { 'SomeNonexistentClassName' }

      before do
        subject.any_instance.should_receive(:fatal)
      end

      it 'raises JobNotFoundError' do
        expect { subject.new(nonexistent_class_name) }.
               to raise_error(QueueingRabbit::JobNotFoundError)
      end
    end

    context 'when valid job is provided' do
      subject { worker }

      it { should be }
      it { should respond_to(:jobs) }
      it 'changes used client to asynchronous' do
        expect { creation.call }.to change { QueueingRabbit.client.to_s }.
                                    from(QueueingRabbit::Client::Bunny.to_s).
                                    to(QueueingRabbit::Client::AMQP.to_s)
      end
    end
  end

  context 'instance methods' do
    let(:connection) { mock }
    let(:queue) { mock }
    let(:payload) { mock }
    let(:metadata) { mock }

    subject { worker }

    describe '#work' do
      before do
        QueueingRabbit.should_receive(:connection).and_return(connection)
        [class_based_job, instance_based_job].each do |job|
          QueueingRabbit.should_receive(:follow_job_requirements).
                         with(job).
                         and_yield(nil, nil, queue)
          connection.should_receive(:listen_queue).
                     with(queue, job.listening_options).
                     and_yield(payload, metadata)
        end

        class_based_job.should_receive(:perform).with(payload, metadata)
        instance_based_job.should_receive(:new).
                           with(payload, metadata).
                           and_return(mock(:perform => nil))
      end

      it 'listens to queues specified by jobs' do
        subject.work
      end

      it 'writes to the log' do
        subject.should_receive(:info).twice
        subject.work
      end

      describe '#work!' do
        it 'runs #work and joins the eventmachine thread' do
          EM.should_receive(:run).and_yield
          subject.work!
        end
      end
    end

    describe "#use_pidfile" do
      let(:file_name) { mock }
      let(:file) { mock }

      before do
        File.should_receive(:open).with(file_name, 'w').and_yield(file)
        file.should_receive(:<<).with(Process.pid)
      end

      it 'writes pid to a file' do
        subject.use_pidfile(file_name)
      end
    end

    describe "#remove_pidfile" do
      let(:file_name) { mock }

      before do
        subject.instance_variable_set(:@pidfile, file_name)
        File.should_receive(:exists?).and_return(true)
        File.should_receive(:delete).with(file_name)
      end

      it 'removes previously created pidfile' do
        subject.remove_pidfile
      end
    end

    describe "#pid" do
      its(:pid) { should == Process.pid }
    end
  end
end