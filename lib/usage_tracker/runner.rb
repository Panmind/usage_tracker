#!/usr/bin/env ruby 

# This is the runner script where EventMachine gets 
# actually invocated.
# Behaviour is defined in the UsageTracker::Reactor module 

$:<< File.expand_path(File.dirname(__FILE__) +  '/..')

require 'usage_tracker'
require 'usage_tracker/reactor'
require 'eventmachine'

module UsageTracker

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
      host, port = UsageTracker.settings.host, UsageTracker.settings.port

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
  
