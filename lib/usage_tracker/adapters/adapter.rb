module UsageTracker
  module Adapters
    class Adapter
      def self::new(adapter, settings)
        klass =
          case adapter
            when 'coachdb'
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
