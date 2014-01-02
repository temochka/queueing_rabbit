require 'stringio'

shared_context "StringIO logger" do

  before(:all) do
    @session_log = StringIO.new
    QueueingRabbit.logger = Logger.new(@session_log)
  end

  after(:all) do
    QueueingRabbit.logger = Logger.new(STDOUT)
  end

end

shared_context "Auto-disconnect" do

  after(:each) do
    QueueingRabbit.disconnect
  end

end

shared_context "No existing connections" do

  before(:each) do
    QueueingRabbit.drop_connection
  end

end

shared_context "Evented spec" do
  include EventedSpec::SpecHelper
end