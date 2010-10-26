#!/usr/bin/env ruby

require 'extras/usage_tracker/initializer'
require 'eventmachine'
require 'json'

module UsageTracker
  module Reactor
    # This method is called upon every data reception
    #
    def receive_data(data)
      doc = parse(data)
      if doc && check(doc)
        store(doc)
      end
    end

    # Debug hook
    if UsageTracker.env == 'test'
      alias :real_receive_data :receive_data
      def receive_data(data)
        UsageTracker.log.debug "Received #{data.inspect}"
        ret = real_receive_data(data)
        UsageTracker.log.debug ret ? "Stored #{ret}" : 'Failed to store input data'
      end
    end

    private
      def parse(data)
        JSON(data)
      rescue JSON::ParserError
        UsageTracker.log.error "Tossing out invalid JSON #{data.inspect} (#{$!.message.inspect})"
        return nil
      end

      def check(doc)
        error =
          if    !doc.kind_of?(Hash) then 'invalid'
          elsif doc.empty?          then 'empty'
          elsif !(missing = check_keys(doc)).empty?
            "#{missing.join(', ')} missing"
          end

        if error
          UsageTracker.log.error "Tossing out invalid document #{doc.inspect}: #{error}"
          return nil
        else
          return true
        end
      end

      def check_keys(doc)
        %w( user_id duration env status ).reject {|k| doc.has_key?(k)}
      end

      def store(doc)
        tries = 0

        begin
          doc['_id'] = make_id
          UsageTracker.database.save_doc(doc)

        rescue RestClient::Conflict => e
          if (tries += 1) < 10
            UsageTracker.log.warn "Retrying to save #{doc.inspect}, try #{tries}"
            retry
          else
            UsageTracker.log.error "Losing '#{doc.inspect}' because of too many conflicts"
          end

        rescue Encoding::UndefinedConversionError
          UsageTracker.log.error "Losing '#{doc.inspect}' because #$!" # FIXME handle this error properly
        end
      end

      # Timestamp as _id has the advantage that documents
      # are sorted automatically by CouchDB.
      #
      # Eventual duplication (multiple servers) is (possibly)
      # avoided by adding a random digit at the end.
      #
      def make_id
        Time.now.to_f.to_s.ljust(16, '0') + rand(10).to_s
      end
  end

  connect!

  # Setup signal handlers
  #
  #  * INT, TERM: graceful exit
  #  * USR1     : rotate logs
  #
  def self.sigexit(sig)
    log "Received SIG#{sig}"
    EventMachine.stop_event_loop
  end

  trap('INT')  { sigexit 'INT'  }
  trap('TERM') { sigexit 'TERM' }
  trap('USR1') { log.rotate  }

  # Run the Event Loop
  #
  EventMachine.run do
    begin
      host, port = UsageTracker.settings.listen.split(':')

      if [host, port].any? {|x| x.strip.empty?}
        raise "Please specify where to listen as host:port"
      end

      unless (1024..65535).include? port.to_i
        raise "Please set a listening port between 1024 and 65535"
      end

      EventMachine.open_datagram_socket host, port, Reactor
      log "Listening on #{host}:#{port} UDP"
      write_pid!

      $stderr.puts "Started, logging to #{log.path}"
      [$stdin, $stdout, $stderr].each {|io| io.reopen '/dev/null'}

    rescue Exception => e
      message = e.message == 'no datagram socket' ? "Unable to bind #{host}:#{port}" : e
      log.fatal message
      $stderr.puts message unless $stderr.closed?
      EventMachine.stop_event_loop
      exit 1
    end
  end

  # Goodbye!
  #
  log 'Exiting'
end
