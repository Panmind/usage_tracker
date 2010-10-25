################################################################
# ATTENTION
# make sure that a event-machine test reactor process is running
#  ruby extras/usage_tracker/reactor.rb test
#
################################################################

# this checks the end-point of the usage tracking (arrival in the database) ->
# consider checking intermediate steps.......
require 'extras/usage_tracker/initializer'

module UsageTracker
  class IntegrationTest < ActionController::IntegrationTest   
    UsageTracker.connect!
    db = UsageTracker.database

    context "a request" do
      should "get tracked in the db backend (couch)" do
        assert_difference 'db.info["doc_count"]' do
          get '/'
          assert_response :success
        end
      end

      should "result in a db-entry containing search results" do
        res, users, assets =
          mock_search_results_for(Array.new(2) { Factory.create(:res)  }),
          mock_search_results_for(Array.new(3) { Factory.create(:user) }),
          mock_search_results_for(Network::AssetsController::ContentModels.map {|name|
            Array.new(2) { Factory(name.underscore.to_sym).reload.asset } }.flatten)

        Res.stubs(:search).returns(res)
        User.stubs(:search).returns(users)
        NetworkAsset.stubs(:search).returns(assets)

        get '/search/e'
        assert_response :success

        doc = db.view('basic/by_timestamp', :descending => true, :limit => 1).rows.first.value
        assert !doc.context.blank?

        assert_equal 'e', doc.context.query
        assert_equal [],  doc.context.tags
        assert_equal nil, doc.context.cat

        assert_equal res.map(&:id),    doc.context.results.res
        assert_equal users.map(&:id),  doc.context.results.users
        assert_equal assets.map(&:id), doc.context.results.assets
      end
    end
  end
end
