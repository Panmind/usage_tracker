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
  if APPLICATION_CONFIG[:test_usage_tracking]
    db = CouchRest.database!(APPLICATION_CONFIG[:usage_tracker_couchdb])
    context "a request" do
      old_count = db.info["doc_count"]
      should "get tracked in the db backend (couch)" do
        #get '/_search#do_not_care_but_need_identifier'
        get '/search/e'
        new_count = db.info["doc_count"]
        assert_response :success
        assert_not_equal old_count,new_count
      end
    end
    context "a search request" do
      should "result in a db-entry containing search results" do
        doc =  db.get(db.get("_all_docs").rows.sort{|a,b| a["id"] <=> b["id"]}[-2]["id"])
        assert doc.keys.include?("search_result")
        assert doc["search_result"]["user"].size > 0
      end
    end
  end
end
