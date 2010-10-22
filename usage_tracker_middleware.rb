require 'socket'
require 'timeout'
require 'extras/usage_tracker/UT_process_dict'

# This middleware sends the incoming request-object to a specified socket,
# writing them to a socket where it can be picked up and parsed for storage
#
class UsageTrackerMiddleware
  Config     = APPLICATION_CONFIG[:usage_tracker]
  Host, Port = Config[:listen].split(':').each(&:freeze) rescue nil

  Save = [
    "REMOTE_ADDR",
    "REQUEST_METHOD",
    "REQUEST_PATH",
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
        :context  => UTProcessDict.get_search_result,
        :environ  => {}
      }

      Save.each {|key| data[:environ][key] = env[key]}

      self.class.track(data.to_json)

    rescue
      self.class.log($!.message)

    end

  ensure
    return response
  end

  cattr_reader :sock
  class << self
    # Adds the UsageTrackerMiddleware to the middleware stack,
    # if configuration is there and the connection to the daemon
    # can be established.
    #
    def insert
      unless Config
        log 'disabled, because configuration is missing'
        return
      end

      unless connect
        log 'disabled, because connection could not be established'
        return
      end

      ActionController::Dispatcher.middleware.insert_before(Rack::Head, self)
      log 'Inserted before Rack::Head'
    end

    def connect
      @@sock = Timeout.timeout(1) { TCPSocket.open(Host, Port) }
      log "Connected to daemon on #{Host}:#{Port}"
      return true

    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      log "cannot connect to daemon on #{Host}:#{Port}"
    rescue Timeout::Error
      log "timed out while connecting to #{Host}:#{Port}"
    end

    def track(data)
      debugger
      return unless sock

      tried = false
      begin
        sock.write(data)
      rescue IOError
        return nil if tried
        tried = true
        connect
        retry
      end
    end

    def log(message)
      message = "Usage Tracker: #{message}"
      $stderr.puts "** #{message}"
      Rails.logger.error message
      nil
    end
  end
end
