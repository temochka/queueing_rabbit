$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'
Bundler.setup(:test)

require 'rspec'
require 'rspec/autorun'
require 'evented-spec'
require 'support/shared_contexts'
require 'support/shared_examples'

require 'queueing_rabbit'

RSpec.configure do |config|  
end
