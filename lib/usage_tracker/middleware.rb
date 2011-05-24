require 'timeout'
require 'usage_tracker/log' 
require 'usage_tracker/context'
require 'usage_tracker/railtie' if defined?(Rails)

# This middleware extracts some data from the incoming request
# and sends it to the reactor, that parses and stores it.
#

module UsageTracker
  class Middleware

    @@host    = 'localhost'
    @@port    = 5984
    @@backend = `hostname`.strip
    @@logger  = UsageTracker::Log.new 

    @@headers = [
      # "REMOTE_ADDR",
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
      @app    = app
    end

    def call(env)
      req_start = Time.now.to_f
      response  = @app.call env
      req_end   = Time.now.to_f

      begin
        data = {
          :user_id   => env['rack.session'][:user_id],
          :remote_ip => env['action_dispatch.remote_ip'].to_s, 
          :duration  => ((req_end - req_start) * 1000).to_i,
          :backend   => @@backend,
          :xhr       => env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest',
          :context   => env[Context.key],
          :env       => {},
          :status    => response[0] # response contains [status, headers, body]
        }

        @@headers.each {|key| data[:env][key.downcase] = env[key] unless env[key].blank?}

        self.class.track(data.to_json)

      rescue
        raise unless response # Error in the application, raise it up
        # Error in usage tracker itself
        @@logger.error($!.message)
        @@logger.error($!.backtrace.join("\n"))
        
      end

      return response
    end

    class << self

      def config(options) 
        @@host    = options.delete :host 
        @@port    = options.delete :port 
        @@backend = options.delete :backend
      end

      def development? 
        defined?(Rails) && Rails.env.development? 
      end

      # Writes the given `data` to the reactor, using the UDP protocol.
      # Times out after 1 second. If a write error occurs, data is lost.
      #

      def track(data)
        Timeout.timeout(1) do

          @@logger.debug("Sending to #{@@host}:#{@@port} : #{data.to_json}") if development? 

          UDPSocket.open do |sock|
            sock.connect(@@host, @@port.to_i)
            sock.write_nonblock(data << "\n")
          end
        end

      rescue Timeout::Error, Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
        @@logger.error "Cannot track data: #{$!.message}"
      end
    end
  end
end
