require 'usage_tracker/adapters/couchdb'
require 'usage_tracker/adapters/mongodb'

module UsageTracker
  class Adapter
    def self::new(settings)
      klass =
        case settings.adapter
          when 'couchdb'
            Adapters::Couchdb
          when 'redis'
            Adapters::Redis
          when 'mongodb'
            Adapters::Mongodb
        end
      klass::new(settings)
    end
  end
end
