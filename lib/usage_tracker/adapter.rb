require 'usage_tracker/adapters/couchdb'

module UsageTracker
  class Adapter
    def self::new(settings)
      klass =
        case settings.adapter
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
