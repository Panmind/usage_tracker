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
      rescue Errno::ECONNREFUSED, RestClient::Exception => e
        raise "Unable to connect to database #{settings.couchdb}: #{e.message}"
      end
    end
  end
end
