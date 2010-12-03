module UsageTracker
  module Context
    @@key = 'usage_tracker.context'.freeze
    mattr_reader :key

    # Sets the env +Key+ variable with the provided +data+
    #
    def usage_tracker_context=(data)
      unless env[key].blank?
        unless Rails.env.test? && !caller.grep(/test\/functional/).blank?
          UsageTracker.log 'WARNING: overwriting context data!'
        end
      end

      env[key] = data
    end

    # Shorthand for self.usage_tracker_context = data
    #
    def usage_tracker_context(data)
      self.usage_tracker_context = data
    end

  end
end
