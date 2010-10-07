#!/usr/bin/env ruby

require 'rubygems'
require 'eventmachine'
require 'pp'

module UsageWriter
  def receive_data(data)
    d = eval data
    puts "usage write received:"
    puts "#{d.class.name}"
    puts "#{d}"
  end
end

EventMachine::run do
  host = '0.0.0.0'
  port = 8765
  EventMachine::start_server host, port, UsageWriter
  puts "Started UsageWriter on #{host}:#{port}..."
end
