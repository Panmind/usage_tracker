require 'pathname'
require 'mongo'
require 'yaml'

module UsageTracker
  class Mongodb
    attr_accessor :database
    def initialize (settings)
      @database =
        Mongo::Connection.new(settings.mongodb['host'], settings.mongodb['port']).db(settings.mongodb['database'])
    rescue Errno::ECONNREFUSED, Mongo::ConnectionError => e
      raise "Unable to connect to database #{settings.mongo['database']}: #{e.message}"
    end

    def save_doc (doc)
      collection = @database['data']
      collection.insert(doc)
    end
  end
end
