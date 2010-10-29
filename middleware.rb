require 'timeout'
require 'extras/usage_tracker/context'

# This middleware sends the incoming request-object to a specified socket,
# writing them to a socket where it can be picked up and parsed for storage
#
module UsageTracker
  class Middleware
    Config     = APPLICATION_CONFIG[:usage_tracker]
    Host, Port = Config[:listen].split(':').each(&:freeze) rescue nil
    ServerName = `hostname`.strip.freeze

    Save = [
      "REMOTE_ADDR",
      "REQUEST_METHOD",
      "PATH_INFO",
      "REQUEST_URI",
      "SERVER_PROTOCOL",
      #"HTTP_VERSION",
      "HTTP_HOST",
      "HTTP_USER_AGENT",
      "HTTP_ACCEPT",
      "HTTP_ACCEPT_LANGUAGE",
      "HTTP_X_FORWARDED_FOR",
      "HTTP_X_FORWARDED_PROTO",
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
          :backend  => ServerName,
          :xhr      => env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest',
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

      # Writes the given `data` to the reactor, using the UDP protocol.
      # Times out after 1 second. If a write error occurs, data is lost.
      #
      def track(data)
        Timeout.timeout(1) do
          UDPSocket.open do |sock|
            sock.connect(Host, Port.to_i)
            sock.write_nonblock(data << "\n")
          end
        end

      rescue Timeout::Error, Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
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
