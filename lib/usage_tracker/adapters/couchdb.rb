require 'pathname'
require 'couchrest'
require 'yaml'

module UsageTracker
  module Adapters
    class Couchdb
      attr_accessor :database
      def initialize (settings)
        @database =
          CouchRest.database!(settings.database).tap do |db|
            db.info
          end
      rescue Errno::ECONNREFUSED, RestClient::Exception => e
        raise "Unable to connect to database #{settings.database}: #{e.message}"
      end

      def save_doc (doc)
        @database.save_doc(doc)
      end
    end
  end
end
