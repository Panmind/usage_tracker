Panmind Usage Tracker
---------------------

What is it?
===========

 1. A `Rack::Middleware` that sends selected parts of the request environment to an UDP socket
 2. An `EventMachine` daemon that opens an UDP socket and sends out received data to CouchDB
 3. A set of CouchDB map-reduce views, for analysis


Does it work?
=============

Yes but the test suite is incomplete. 
If you can help in complete the test suite, it is much appreciated :-).

Deploying
=========

 * Add the usage\_tracker gem to your Gemfile and require the middleware

   gem 'usage\_tracker', :require => 'usage\_tracker/middleware'

 * Add the Middleware to your application:

    Your::Application.config.middleware.use UsageTracker::Middleware

 * The daemon can be started manually with the following command, inside a Rails.root:

     $ usage_tracker [environment]

   `environment` is optional and will default to "development" if no command line
   option nor the RAILS\_ENV environment variable are set.

   or can be put under Upstart using the provided configuration file located in
   `config/usage_tracker_upstart.conf`. Check it out and modify it to suit your needs.

   The daemon logs to `log/usage_tracker.log` if the log directory exists and rotates its 
   logs when receives the USR1 signal. If log directory does not exist it logs in the 
   current directory.

 * The daemon writes its pid into tmp/pids/usage\_tracker.pid

 * The daemon connects to a Couch database named `usage_tracker` running on `localhost`,
   default port `5984/TCP`, and listens on `localhost`, port `5985/UDP` by default.
   You can change these settings via a `config/usage_tracker.yml` file. See the example
   in the `config` directory of the gem distribution.

 * The CouchDB instance must be running, the database is created (and updated)
   if necessary.

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
app's integration test suite. Some sample code has been brutally extracted from 
Panmind's codebase and is included in middleware\_test.rb file. 

