require 'rubygems'
require 'erb'
require 'yaml'
require 'pathname'
require 'ostruct'
require 'couchrest'
require 'active_support/core_ext/object/blank'
require 'usage_tracker/log'
require 'usage_tracker/adapter'

module UsageTracker
  class << self
    # Memoizes the current environment
    def env
      @env ||= ENV['RAILS_ENV'] || ARGV[0] || 'development'
    end

    @@defaults = {
      'adapter' => 'couchdb',
      'couchdb' => 'http://localhost:5984/usage_tracker',
      'listen'  => '127.0.0.1:5985'
    }

    # Memoizes settings from the ./config/usage_tracker.yml file,
    # relative from __FILE__ and searches for the "usage_tracker"
    # configuration block. Raises RuntimeError if it cannot find
    # the configuration.
    #
    def settings
      @settings ||= begin
        log "Loading #{env} environment"

        rc_file  = Pathname.new('.').join('config', 'usage_tracker.yml')
        settings = YAML.load(rc_file.read)[env] if rc_file.exist?

        if settings.blank?
          settings = @@defaults
          log "#{env} configuration block not found in #{rc_file}, using defaults"
        elsif settings.values_at(*%w(couchdb listen)).any?(&:blank?)
          raise "Incomplete configuration: please set the 'couchdb' and 'listen' keys"
        end

        host, port = settings.delete('listen').split(':')

        if [host, port].any? {|x| x.strip.empty?}
          raise "Please specify where to listen as host:port"
        end

        settings['host'], settings['port'] = host, port.to_i

        OpenStruct.new settings
      end
    end

    def database
      @database or raise "Not connected to the database"
    end

    # Connects to the configured CouchDB and memoizes the
    # CouchRest::Database connection into an instance variable
    # and calls +load_views!+
    #
    # Raises RuntimeError if the connection could not be established
    #
    def connect!
      @adapter = Adapter::new settings
      @database = @adapter.database
    end

    def write_pid!(pid = $$)
      dir = Pathname.new('.').join('tmp', 'pids')
      dir = Pathname.new(Dir.tmpdir) unless dir.directory?
      dir.join('usage_tracker.pid').open('w+') {|f| f.write(pid)}
    end

    def log(message = nil)
      @log ||= Log.new
      message ? @log.info(message) : @log
    end

    def raise(message)
      log.error message
      Kernel.raise Error, message
    end
  end

  class Error < StandardError; end
end
