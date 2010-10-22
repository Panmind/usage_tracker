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
      d['_id'] = make_id

      begin
        UsageTracker.database.save_doc(d)
      rescue RestClient::Conflict
        d['_id'] = make_rand_id
        retry
      rescue Encoding::UndefinedConversionError
        :ok # FIXME handle this error properly
      end
    end

    private
      # timestamp as _id has the advantage that documents
      # are sorted automatically by couchdb...
      #
      def make_id
        Time.now.to_f.to_s.ljust(16, '0')
      end

      # ...eventual duplication (multiple servers) of said
      # id are avoided by adding a random digit at the end
      #
      def make_rand_id
        make_id + rand(10).to_s
      end
  end
end

UsageTracker.connect!

EventMachine.run do
  host, port = UsageTracker.settings.reactor.split(':')
  EventMachine::start_server host, port, UsageTracker::Reactor
  UsageTracker.log "Started Reactor on #{host}:#{port}"
end
