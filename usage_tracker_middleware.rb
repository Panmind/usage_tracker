require 'rack/utils'
require 'socket'
require 'extras/usage_tracker/UT_process_dict'


# this middleware sends the incoming request-object to a specified socket.
class UsageTrackerMiddleware
  def initialize(app, server_and_port)
    @app = app
    @server, @port = server_and_port.split(":")
  end

  def call(env)
		arrival = Time::now
    response = @app.call(env)
    duration = ((Time::now - arrival) * 1000).to_i # convert to millisecs
		begin
      sock = TCPSocket.open(@server, @port.to_i)
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
		 end
			data_object[:duration] = duration
			sr = UTProcessDict::get_search_result
			data_object[:search_result] = sr if sr
      sock.write(data_object)
      sock.close
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      :ok
    end
    response
  end
end
