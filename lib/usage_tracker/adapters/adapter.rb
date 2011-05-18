require 'usage_tracker/adapters/couchdb'

module UsageTracker
  module Adapters
    class Adapter
      def self::new(adapter, settings)
        klass =
          case adapter
            when 'couchdb'
              Couchdb
            when 'redis'
              Redis
            when 'mongodb'
              Mongodb
          end
        klass::new(settings)
      end
    end
  end
end
