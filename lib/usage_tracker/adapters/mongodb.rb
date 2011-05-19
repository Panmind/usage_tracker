require 'pathname'
require 'mongo'
require 'yaml'

module UsageTracker
  module Adapters
    class Mongodb
      attr_accessor :database
      def initialize (settings)
        @database =
          Mongo::Connection.new(settings.mongodb.host, settings.mongodb.host).db(settings.mongodb.database)
      rescue Errno::ECONNREFUSED, Mongo::ConnectionError => e
        raise "Unable to connect to database #{settings.mongo.database}: #{e.message}"
      end
  end
end
