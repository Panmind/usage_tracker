#!/usr/bin/env ruby

require 'extras/usage_tracker/initializer'
require 'eventmachine'
require 'json'

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


  connect!

  EventMachine.run do
    begin
      host, port = UsageTracker.settings.listen.split(':')

      if [host, port].any? {|x| x.strip.empty?}
        raise "Please specify where to listen as host:port"
      end

      unless (1024..65535).include? port.to_i
        raise "Please set a listening port higher between 1024 and 65535"
      end

      EventMachine.start_server host, port, Reactor
      log "Started Reactor on #{host}:#{port}"
    rescue RuntimeError => e
      raise(
        e.message == 'no acceptor' ? "Unable to bind to #{host}:#{port}" : e.message
      )
    end
  end
end
