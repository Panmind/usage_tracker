# this middleware writes request objects to a socket where it can be parsed & picked up for storage
ActionController::Dispatcher.middleware.insert_before(
    Rack::Head,
    UsageTrackerMiddleware
)

