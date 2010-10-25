module UsageTracker
  module Context
    extend self
    Key = :usage_tracker_ctx

    def set(data)
      unless Thread.current[Key].blank?
        UsageTracker.log "WARNING: overwriting context data!"
      end

      Thread.current[Key] = data
    end

    # Reads the current context data and sets the Thread.current
    # +Key+ variable to +nil+
    #
    def get
      ctx = Thread.current[Key]
      Thread.current[Key] = nil
      return ctx
    end

  end
end
