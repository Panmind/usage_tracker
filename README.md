Panmind Usage Tracker
---------------------

What is it?
===========

 1. A Rack::Middleware that sends selected parts of the request environment to a socket (middleware.rb)
 2. An EventMachine daemon that opens an UDP socket and sends out received data to CouchDB (reactor.rb)
 3. A set of CouchDB map-reduce views, for analysis                                         (views.yml)


Does it work?
=============

Yes, but currently this release is deeply coupled to Rails and to Panmind,
thus some work should be done to make this code independent from the logic
of a specific app.

Fork it and do it, if you're interested in logging HTTP requests to your
app into CouchDB for analysis.

These instructions as well have to be updated. We just can't wait to see
the Open Source community do it :-).


Deploying
=========

 * Verify to have the required configuration stanza in `config/settings.yml`:

    :usage_tracker:
      :couchdb: "http://127.0.0.1:5984/pm_usage" # The CouchDB database URI
      :listen:  "127.0.0.1:8765"                 # Where to listen/connect to

 * The Middleware gets loaded automatically by the Rails app if the configuration
   is present and valid;

 * The daemon can be started manually with the following command:

     $ ruby extras/usage_tracker/reactor.rb [environment]

   `environment` is optional and will default to "development" if no command line
   option nor the RAILS_ENV environment variable are set.

   or can be put under Upstart using the provided configuration file located in
   `extras/fabric/files/upstart/panmind_usage_tracker.conf`.

   The daemon logs to `log/usage_tracker.log` and rotates its logs when receives
   the USR1 signal.

 * The CouchDB instance must be running, the database is created (and updated)
   if necessary.

 * If the daemon cannot start, e.g. because of unavailable database or listening
   address, it will print a diagnostig message to STDERR, log to usage_tracker.log
   and exit with an 1 status.

 * The daemon exits gracefully if it receives the INT or the TERM signals.

 * The daemon writes its pid into tmp/pids/usage_tracker.pid

Testing
=======

If the configuration is present, the `test/integration/usage_tracker_test.rb`
tests some (but not all, unluckily, more work need to be done) parts of the
workflow.

To run the test, make sure you have an instance of the daemon running.

