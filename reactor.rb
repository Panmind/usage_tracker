#!/usr/bin/env ruby

require 'rubygems'
require 'json/add/rails'
require 'eventmachine'
require 'couchrest'
require 'extras/usage_tracker/initializer'
require 'yaml'

module UsageWriter
    # basic setup
    ARGV.push "development" unless  ARGV.length > 0
    SETTINGS =  YAML::load(File.open(File.dirname(__FILE__) + "/../../config/settings.yml"))[ARGV[0]]
    @couchdb_url = SETTINGS[:usage_tracker][:couchdb]
    puts "using couchdb database:#{@couchdb_url}"
    ARGV.push @couchdb_url
    UsageTrackerSetup.init(@couchdb_url)
    
    # this function assures that a global variable for the couchrest database-object is available 
    # it is called EVERY TIME a new connection is made 
    #     - given the use of this event-machine reactor as a server for a webapp this means that 
    #       this function is called on every connection) 
    def initialize
      @db ||= CouchRest.database!(ARGV[1])
    end

    # this function is called upon every data reception
    def receive_data(data)
      d = eval data
      # timestamp as _id has the advantage that documents are sorted automatically by couchdb, 
      # eventual duplication (multiple servers) of the id are avoided by adding a random string at the end 
      begin
        begin
          d["_id"] = Time.now.to_f.to_s.ljust(16,"0")
          @db.save_doc(d)
        rescue RestClient::Conflict
          d["_id"] = Time.now.to_f.to_s.ljust(16,"0") + (0..9).to_a.rand.to_s
          @db.save_doc(d)
        end
      rescue Encoding::UndefinedConversionError
        :ok
      end
    end

end


# the reactor
EventMachine::run do
    #puts "debug: #{ARGV.inspect}"
    env = ARGV.length > 0 ? ARGV[0] : "development"
    em_url = UsageWriter::SETTINGS[:usage_tracker][:reactor]
    host = em_url.split(":")[0]
    port =  em_url.split(":")[1]
    EventMachine::start_server host, port, UsageWriter
    puts "Started UsageWriter on #{host}:#{port}..."
end
