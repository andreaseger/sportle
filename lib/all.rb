require 'schedule'
require 'parser'
require 'item'
require 'user'

#require 'hiredis'
require 'redis'
require 'redis/value'
require 'redis/list'
require 'redis/set'
require 'redis/sorted_set'
require 'redis/counter'

redis_config = if ENV['SPORTLE_REDIS_URL']
  require 'uri'
  uri = URI.parse ENV['SPORTLE_REDIS_URL']
  { :host => uri.host, :port => uri.port, :password => uri.password, :db => uri.path.gsub(/^\//, '') }
else
  {}
end

$redis = Redis.new(redis_config)

