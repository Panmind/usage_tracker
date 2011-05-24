require 'logger'

module UsageTracker
  class Log

    Levels = {
        :fatal => Logger::FATAL, 
        :erorr => Logger::ERROR, 
        :warn  => Logger::WARN, 
        :info  => Logger::INFO, 
        :debug => Logger::DEBUG 
    }

    attr_reader :path

    [:debug, :info, :warn, :error, :fatal].each do |severity|
      define_method(severity) {|*args| @logger.send(severity, *args)}
    end

    def initialize
      open
    end

    def path
      @path ||= if File.directory?('log')
        Pathname.new('.').join('log', 'usage_tracker.log')
      else
        Pathname.new('usage_tracker.log')
      end
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

    def level=(level)
      level = level.to_sym 
      raise "Invalid log level" unless Levels.keys.include?(level)
      @logger.level = Levels[level]
    end
  end
end
