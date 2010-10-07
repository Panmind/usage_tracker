#!/usr/bin/env ruby

require 'rubygems'
require 'json/add/rails'
require 'eventmachine'
require 'couchrest'
require 'extras/usage_tracker/initializer'

module UsageWriter
UsageTrackerSetup.init()
#function(doc) {
#  emit([doc._id,doc.user_id], doc);
#}
  def initialize
    @db ||= CouchRest.database!("localhost:5984/pm_usage")
  end
  def receive_data(data)
    d = eval data
    d["_id"] = Time.now.to_f.to_s.ljust(16,"0")
    puts "usage write received:"
    puts "#{d.class.name}"
    puts "#{d}"
    puts d.to_json
    @db.save_doc(d)
  end
end

EventMachine::run do
  host = '0.0.0.0'
  port = 8765
  EventMachine::start_server host, port, UsageWriter
  puts "Started UsageWriter on #{host}:#{port}..."
end
