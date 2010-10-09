#!/usr/bin/env ruby

require 'rubygems'
require 'json/add/rails'
require 'eventmachine'
require 'couchrest'
require 'extras/usage_tracker/initializer'
require 'yaml'

module UsageWriter
env = ARGV.length > 0 ? ARGV[0] : "development"
@couchdb_url = YAML::load(File.open(File.dirname(__FILE__) + "/../../config/settings.yml"))[env][:usage_tracker_couchdb]
ARGV.push @couchdb_url
UsageTrackerSetup.init(@couchdb_url)
  # this function assures that a global variable for the couchrest database-object is available (consider making the DB-localisation settable from the application config)
  # this function is called EVERY TIME a new connection is made (given the use of this event-machine reactor as a server for a webapp this means that this function is called on every connection) 
  def initialize
    @db ||= CouchRest.database!(ARGV[1])
  end
  # this function is called upon every data reception
  def receive_data(data)
    d = eval data
    # timestamp as _id has the advantage that documents are sorted automatically by couchdb, eventual duplication (multiple servers) of the id are avoided by adding a random string at the end 
    begin
      d["_id"] = Time.now.to_f.to_s.ljust(16,"0")
    rescue RestClient::Conflict
      d["_id"] = Time.now.to_f.to_s.ljust(16,"0") + (0..9).to_a.rand.to_s
    end
@db.save_doc(d)
  end
end

# the reactor
EventMachine::run do
  host = '0.0.0.0'
  port = 8765
  EventMachine::start_server host, port, UsageWriter
  puts "Started UsageWriter on #{host}:#{port}..."
end
