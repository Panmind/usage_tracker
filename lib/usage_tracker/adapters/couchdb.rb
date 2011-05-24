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
        doc['_id'] = make_id if doc['_id'].nil?
        @database.save_doc(doc)
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
  end
end
