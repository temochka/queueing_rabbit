require 'stringio'

shared_context "StringIO logger" do

  before(:all) do
    QueueingRabbit.logger = Logger.new(StringIO.new)
  end

  after(:all) do
    QueueingRabbit.logger = Logger.new(STDOUT)
  end

end

shared_context "Evented spec" do
  include EventedSpec::SpecHelper
end