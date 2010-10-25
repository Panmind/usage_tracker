require 'kgio'
require 'timeout'
require 'extras/usage_tracker/context'

# This middleware sends the incoming request-object to a specified socket,
# writing them to a socket where it can be picked up and parsed for storage
#
module UsageTracker
class Middleware
  Config     = APPLICATION_CONFIG[:usage_tracker]
  Host, Port = Config[:listen].split(':').each(&:freeze) rescue nil

  Save = [
    "REMOTE_ADDR",
    "REQUEST_METHOD",
    #"REQUEST_PATH",
    "PATH_INFO",
    "REQUEST_URI",
    "SERVER_PROTOCOL",
    #"HTTP_VERSION",
    "HTTP_HOST",
    "HTTP_USER_AGENT",
    "HTTP_ACCEPT",
    #"HTTP_ACCEPT_LANGUAGE",
    #"HTTP_ACCEPT_ENCODING",
    #"HTTP_ACCEPT_CHARSET",
    #"HTTP_KEEP_ALIVE",
    "HTTP_CONNECTION",
    #"HTTP_COOKIE",
    #"HTTP_CACHE_CONTROL",
    #"SERVER_NAME",
    #"SERVER_PORT",
    "QUERY_STRING"
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    req_start = Time.now.to_f
    response  = @app.call env
    req_end   = Time.now.to_f

    begin
      data = {
        :user_id  => env['rack.session'][:user_id],
        :duration => ((req_end - req_start) * 1000).to_i,
        :context  => Context.get,
        :env      => {},
        :status   => response[0] # response contains [status, headers, body]
      }

      Save.each {|key| data[:env][key.downcase] = env[key] unless env[key].blank?}

      self.class.track(data.to_json)

    rescue
      self.class.log($!.message)
      self.class.log($!.backtrace.join("\n"))
    end

  ensure
    return response
  end

  class << self
    # Adds the UsageTracker::Middleware to the middleware stack,
    # if configuration is present.
    #
    def insert
      return unless enabled?
      ActionController::Dispatcher.middleware.insert_before(Rack::Head, self)
      log 'inserted before Rack::Head'
    end

    # Tries to connect to the server and write the given `data`,
    # with a 1 second timeout.
    #
    # If a connect or write error occurs, data is lost.
    #
    def track(data)
      Timeout.timeout(1) do
        Kgio::TCPSocket.open(Host, Port.to_i) do |sock|
          sock.kgio_write(data << "\n")
        end
      end

    rescue IOError, Errno::EPIPE, Errno::ECONNRESET,
      Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Timeout::Error
      log "Cannot track data: #{$!.message}"
    end

    def enabled?
      !Config.nil?
    end

    def log(message)
      message = "Usage Tracker: #{message}"
      Rails.logger.error message
      $stderr.puts "** #{message}"
    end
  end
end
end
