require 'pathname'
require 'couchrest'
require 'yaml'

module UsageTracker
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

    def save_doc (doc)
      @database.save_doc(doc)
    end
  end
end
