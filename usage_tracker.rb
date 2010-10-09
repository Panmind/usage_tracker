# adds the UsageTrackerMiddleware to the middleware stack
# this middleware writes request objects to a socket where it can be picked up and parsed for storage: 
# see app/middleware/usage_tracker_middleware.rb
ActionController::Dispatcher.middleware.insert_before(
    Rack::Head,
    UsageTrackerMiddleware
)

