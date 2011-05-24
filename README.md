Panmind Usage Tracker
---------------------

What is it?
===========

 1. A `Rack::Middleware` that sends selected parts of the request environment to an UDP socket
 2. An `EventMachine` daemon that opens an UDP socket and sends out received data to a database

Does it work?
=============

Yes, we are using it in production. 
If you can help in complete the test suite, it is much appreciated :-).

Deploying
=========

 * Add the usage\_tracker gem to your Gemfile and require the middleware

   gem 'usage\_tracker', :require => 'usage\_tracker/middleware'

 * Configure the middleware and plug it into your application:

    UsageTracker::Middleware.config(:host => '192.168.1.20', :port => '8840')
    Your::Application.config.middleware.use UsageTracker::Middleware

 * Install the gem on the target machine and run it with this command:

     $ usage_tracker [environment]

   If you run it into a Rails.root it will log and write pids in canonical dirs.

   `environment` is optional and will default to "development" if no command line
   option nor the RAILS\_ENV environment variable are set.

   or can be put under Upstart using the provided configuration file located in
   `config/usage_tracker_upstart.conf`. Check it out and modify it to suit your needs.

   The daemon logs to `usage_tracker.log` if the log directory exists and rotates its 
   logs when receives the USR1 signal. 

 * The daemon writes its pid into usage\_tracker.pid

 * The daemon can be configured to work with couchdb or mongodb adapter. Look at the 
   sample configuration file for hints.

 * If the daemon cannot start, e.g. because of unavailable database or listening
   address, it will print a diagnostig message to STDERR, log to usage\_tracker.log
   and exit with status of 1.

 * The daemon exits gracefully if it receives the INT or the TERM signals.

Testing
=======

Our will is to test the Evented code in isolation using rspec and em-rspec gem. 
Tests are still incomplete. You can start the running: 

> bundle exec rspec spec 

All required gems for testing should be installed running: 

> bundle install

About the middleware, it's probably better for you to test that in your own 
app's integration test suite. 

