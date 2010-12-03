module UsageTracker
  module Context
    extend self
    Key = 'usage_tracker.context'

    def set(data)
      unless env[Key].blank?
        unless Rails.env.test? && !caller.grep(/test\/functional/).blank?
          Middleware.log 'WARNING: overwriting context data!'
        end
      end

      env[Key] = data
    end

    # Reads the current context data and sets
    # the env +Key+ variable to +nil+
    #
    def get
      ctx = env[Key]
      env[Key] = nil
      return ctx
    end

  end
end
