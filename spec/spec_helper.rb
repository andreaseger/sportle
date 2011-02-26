require 'rubygems'
require 'rspec'
require 'mocha'

require File.dirname(__FILE__) + '/../lib/all'

Rspec.configure do |config|
  config.mock_with :mocha
  
  config.before(:each) do
    DB.select 12
    DB.flushdb
  end
end
