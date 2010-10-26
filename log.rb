require 'logger'

module UsageTracker
  class Log
    attr_reader :path

    [:info, :warn, :error, :fatal].each do |severity|
      define_method(severity) {|*args| @logger.send(severity, *args)}
    end

    def initialize
      open
    end

    def path
      @path ||= Pathname.new(__FILE__).dirname.
        join('..', '..', 'log', 'usage_tracker.log').
        realpath.to_s.freeze
    end

    def open
      @logger           = Logger.new(path.to_s)
      @logger.formatter = Logger::Formatter.new
      @logger.info 'Log opened'

    rescue
      raise Error, "Cannot open log file #{path}"
    end

    def close
      return unless @logger

      @logger.info 'Log closed'
      @logger.close
      @logger = nil
    end

    def rotate
      close
      open
    end
  end
end
