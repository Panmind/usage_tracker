require 'pathname'
require 'couchrest'
require 'yaml'

module UsageTracker
  module Adapters
    class Couchdb
      attr_accessor :database
      def initialize (settings)
        @database =
          CouchRest.database!(settings.couchdb).tap do |db|
            db.info
          end
        load_views!
      rescue Errno::ECONNREFUSED, RestClient::Exception => e
        raise "Unable to connect to database #{settings.couchdb}: #{e.message}"
      end

      private
      # Loads CouchDB views from views.yml and verifies that
      # they are loaded in the current instance, upgrading
      # them if necessary.
      def load_views!
        new = YAML.load ERB.new(
          Pathname.new(__FILE__).dirname.join('..', '..', '..', 'config', 'views.yml').read
        ).result

        id  = new['_id']
        old = @database.get id

        if old['version'].to_i < new['version'].to_i
          log "Upgrading Design Document #{id} to v#{new['version']}"
          @database.delete_doc old
          @database.save_doc new
        end

      rescue RestClient::ResourceNotFound
        log "Creating Design Document #{id} v#{new['version']}"
        @database.save_doc new
      end
    end
  end
end
