require 'rubygems'
require 'erb'
require 'yaml'
require 'pathname'
require 'ostruct'
require 'couchrest'
require 'active_support/core_ext/object/blank'
require 'usage_tracker/log'

module UsageTracker
  class << self
    # Memoizes the current environment
    def env
      @env ||= ENV['RAILS_ENV'] || ARGV[0] || 'development'
    end

    @@defaults = {
      'couchdb' => 'http://localhost:5984/usage_tracker',
      'listen'  => '127.0.0.1:5985'
    }

    # Memoizes settings from ../../../config/settings.yml config,
    # relative from __FILE__ and searches for the "usage_tracker"
    # configuration block. Raises RuntimeError if it cannot find
    # the configuration.
    #
    def settings
      @settings ||= begin
        log "Loading #{env} environment"

        rc_file  = root.join('config.yml')
        settings = YAML.load(rc_file.read)[env] if rc_file.exist?

        if settings.blank?
          settings = @@defaults
          log "#{env} configuration block not found in #{rc_file}, using defaults"
        elsif settings.values_at(:couchdb, :listen).any?(&:nil?)
          raise "Incomplete configuration: please set the 'couchdb' and 'listen' keys"
        end

        host, port = settings.delete(:listen).split(':')

        if [host, port].any? {|x| x.strip.empty?}
          raise "Please specify where to listen as host:port"
        end

        settings[:host], settings[:port] = host, port.to_i

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
      @database =
        CouchRest.database!(settings.couchdb).tap do |db|
          db.info
          log "Connected to database #{settings.couchdb}"
        end

      load_views!
    rescue Errno::ECONNREFUSED, RestClient::Exception => e
      raise "Unable to connect to database #{settings.couchdb}: #{e.message}"
    end

    def write_pid!(pid = $$)
      root.join('usage_tracker.pid').open('w+') {|f| f.write(pid)}
    end

    def log(message = nil)
      @log ||= Log.new
      message ? @log.info(message) : @log
    end

    def raise(message)
      log.error message
      Kernel.raise Error, message
    end

    private
      # Returns the UsageTracker.root as a Pathname
      #
      def root
        Pathname.new(__FILE__).dirname
      end

      # Loads CouchDB views from views.yml and verifies that
      # they are loaded in the current instance, upgrading
      # them if necessary.
      def load_views!
        new = YAML.load ERB.new(
          Pathname.new(__FILE__).dirname.join('views.yml').read
        ).result

        id  = new['_id']
        old = database.get id

        if old['version'].to_i < new['version'].to_i
          log "Upgrading Design Document #{id} to v#{new['version']}"
          database.delete_doc old
          database.save_doc new
        end

      rescue RestClient::ResourceNotFound
        log "Creating Design Document #{id} v#{new['version']}"
        database.save_doc new
      end
  end

  class Error < StandardError; end
end
