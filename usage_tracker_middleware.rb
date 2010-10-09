require 'rack/utils'
require 'socket'

# this middleware sends the incoming request-object to a specified socket.
class UsageTrackerMiddleware
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
		arrival = Time::now
    response = @app.call(env)
    duration = ((Time::now - arrival) * 1000).to_i # convert to millisecs
		begin

      sock = TCPSocket.open("localhost", 8765)
      request = Rack::Request.new(env)
      session = env["rack.session"]
      if true || @options[:reassemble]
# all environment keys:
# ["REMOTE_ADDR", "REQUEST_METHOD", "REQUEST_PATH", "PATH_INFO", "REQUEST_URI", "SERVER_PROTOCOL", "HTTP_VERSION", "HTTP_HOST", "HTTP_USER_AGENT", "HTTP_ACCEPT", "HTTP_ACCEPT_LANGUAGE", "HTTP_ACCEPT_ENCODING", "HTTP_ACCEPT_CHARSET", "HTTP_KEEP_ALIVE", "HTTP_CONNECTION", "HTTP_COOKIE", "HTTP_CACHE_CONTROL", "rack.url_scheme", "SERVER_NAME", "SERVER_PORT", "QUERY_STRING", "rack.input", "rack.errors", "rack.multiprocess", "rack.multithread", "rack.run_once", "rack.version", "SCRIPT_NAME", "SERVER_SOFTWARE", "rack.logger", "rack.session", "rack.session.options", "rack.request.cookie_string", "rack.request.cookie_hash"]

         data_object = {:user_id => env['rack.session'][:user_id]}
         ["REMOTE_ADDR", 
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
	  "QUERY_STRING"].each do |it|
	      data_object[it.downcase.to_sym] = env[it]
      end
 
        #sock.write(env.class.name)
        #sock.write("wer isses?: #{session[:user_id]} inspect: #{session.inspect}")
        #sock.write(env.keys)
      end
			data_object[:duration] = duration
      sock.write(data_object)
      #sock.write(Marshal.dump(request))
      sock.close
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      :ok
    end
    response
  end
end
