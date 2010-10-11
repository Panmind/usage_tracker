# in order for this test to pass, the event-machine reactor which - as a server - 
# forwards events to couchdb has to be running.

################################################################
# ATTENTION
# make sure that a event-machine test reactor process is running
# run from the root directory:
#  ruby extras/usage_tracker/reactor.rb test
#
# ##############################################################

require File.dirname(__FILE__) + '/../test_helper'
require 'couchrest'

# this checks the end-point of the usage tracking (arrival in the database) ->
# consider checking intermediate steps.......
class UsageTrackerMiddlewareTest < ActionController::IntegrationTest   
  context "a request" do
    if APPLICATION_CONFIG[:test_usage_tracking]
      db = CouchRest.database!(APPLICATION_CONFIG[:usage_tracker_couchdb])
      old_count = db.info["doc_count"]
      should "get tracked in the db backend (couch)" do
        get '/_'
        new_count = db.info["doc_count"]
        assert_response :success
        assert_not_equal old_count,new_count
      end
    end
  end
end
