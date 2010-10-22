#!/usr/bin/env ruby

require 'rubygems'
require 'json/add/rails'
require 'eventmachine'
require 'couchrest'
require 'extras/usage_tracker/initializer'
require 'yaml'

module UsageTracker
  module Reactor
    # this function is called upon every data reception
    #
    def receive_data(data)
      d = eval data # FIXME SECURITY HOLE
      # timestamp as _id has the advantage that documents are sorted automatically by couchdb, 
      # eventual duplication (multiple servers) of the id are avoided by adding a random string at the end 
      begin
        d["_id"] = Time.now.to_f.to_s.ljust(16,"0")
        UsageTracker.database.save_doc(d)
      rescue RestClient::Conflict
        d["_id"] = Time.now.to_f.to_s.ljust(16,"0") + (0..9).to_a.rand.to_s
        retry
      rescue Encoding::UndefinedConversionError
        :ok # FIXME handle this error properly
      end
    end

end

UsageTracker.connect!

EventMachine.run do
  host, port = UsageTracker.settings.reactor.split(':')
  EventMachine::start_server host, port, UsageTracker::Reactor
  UsageTracker.log "Started Reactor on #{host}:#{port}"
end
