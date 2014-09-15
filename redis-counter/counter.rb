require 'rubygems'
require 'redis'
require 'securerandom'

redis = Redis.new(host: ENV['REDIS_PORT_6379_TCP_ADDR'], port: ENV['REDIS_PORT_6379_TCP_PORT'])

clear = ENV['COUNTER_CLEAR'] || false
key = ENV['COUNTER_KEY'] || 'debug:counter:stack'
count = ENV['COUNTER_COUNT'].to_i
interval = ENV['COUNTER_INTERVAL'].to_i

redis.del(key) if clear

ack = []
err = []
count.times do
  uuid = SecureRandom.uuid
  begin
    redis.rpush(key, uuid)
    $stderr.puts "ack #{uuid}"
    ack.push uuid
  rescue Redis::BaseError => e
    $stderr.puts "err #{uuid}: #{e}"
    err.push uuid
    redis = Redis.new(host: ENV['REDIS_PORT_6379_TCP_ADDR'], port: ENV['REDIS_PORT_6379_TCP_PORT'])
  end
  sleep (interval / 1000.0)
end

persisted = redis.lrange(key, 0, -1)

missing = 0
ack.each do |v|
  if ! persisted.include?(v)
    $stderr.puts "ack'd #{v} missing from persisted set"
    missing += 1
  end
end

phantom = 0
err.each do |v|
  if persisted.include?(v)
    $stderr.puts "err'd #{v} phantom in persisted set"
    phantom += 1
  end
end

$stdout.puts "ack'd: #{ack.size} (#{missing} missing) err'd: #{err.size} (#{phantom} phantom)"
