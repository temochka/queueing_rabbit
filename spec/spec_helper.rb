$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'bundler'
Bundler.setup(:test)

require 'rspec'
require 'rspec/autorun'
require 'unit/support/context_string_io_logger'

require 'queueing_rabbit'

RSpec.configure do |config|  
end
