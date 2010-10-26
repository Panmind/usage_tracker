require 'rubygems'
require 'erb'
require 'yaml'
require 'pathname'
require 'ostruct'
require 'couchrest'
require 'extras/usage_tracker/log'

module UsageTracker
  class << self
    # Memoizes the current environment
    def env
      @env ||= ENV['RAILS_ENV'] || ARGV[0] || 'development'
    end

    # Memoizes settings from ../../../config/settings.yml config,
    # relative from __FILE__ and searches for the "usage_tracker"
    # configuration block. Raises RuntimeError if it cannot find
    # the configuration.
    #
    def settings
      @settings ||= begin
        log "Loading #{env} environment"

        rc_file = Pathname.new(__FILE__).join('..', '..', '..', 'config', 'settings.yml')
        raise "Configuration file #{rc_file} not found" unless rc_file.exist?

        settings = YAML.load_file(rc_file.to_s)[env][:usage_tracker]

        unless settings
          raise ":usage_tracker configuration block not found in #{rc_file}"
        end

        if settings.values_at(:couchdb, :listen).any?(&:nil?)
          raise "Incomplete configuration: please set the 'couchdb' and 'listen' keys"
        end

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
    rescue Errno::ECONNREFUSED
      raise "Unable to connect to database #{settings.couchdb}"
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
