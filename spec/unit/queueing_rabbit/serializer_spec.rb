require 'spec_helper'

describe QueueingRabbit::Serializer do
  subject { Class.new { extend QueueingRabbit::Serializer } }
  let(:args) { {:a => 1, :b => 2, :c => 3} }

  describe ".serialize" do
    it "serializes arguments to JSON" do
      subject.serialize(args).should == JSON.dump(args)
    end
  end

  describe ".deserialize" do
    it "deserializes arguments from JSON to symbolized hash" do
      subject.deserialize(JSON.dump(args)).should == args
    end
  end

  describe ".symbolize_keys" do
    let(:stringified_args) { { "a" => 1, "b" => 2, "c" => 3 } }

    it "symbolizes keys of provided Hash" do
      subject.send(:symbolize_keys, stringified_args).should == args
    end
  end
end