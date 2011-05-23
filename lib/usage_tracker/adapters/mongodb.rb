require 'pathname'
require 'mongo'
require 'yaml'

module UsageTracker
  module Adapters
    class Mongodb
      attr_accessor :database
      def initialize (settings)
        @database =
          db = Mongo::Connection.new(settings.database['host'], settings.database['port']).db(settings.database['name'])
          @collection = db[settings.database['collection']]
          db
      rescue Errno::ECONNREFUSED, Mongo::ConnectionError => e
        raise "Unable to connect to database #{settings.database['name']} with #{settings.adapter} adapter: #{e.message}"
      end

      def save_doc(doc)
        @collection.insert(doc)
      end
    end
  end
end
