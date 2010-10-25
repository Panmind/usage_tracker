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

    context "a request" do
      should "get tracked in the db backend (couch)" do
        assert_difference 'UsageTracker.database.info["doc_count"]' do
          get '/'
          assert_response :success
        end
      end
    end

    fast_context "a search request" do
      setup do
        @res, @users, @assets =
          mock_search_results_for(Array.new(2) { Factory.create(:res)  }),
          mock_search_results_for(Array.new(3) { Factory.create(:user) }),
          mock_search_results_for(Network::AssetsController::ContentModels.map {|name|
            Array.new(2) { Factory(name.underscore.to_sym).reload.asset } }.flatten)

        Res.stubs(:search).returns(@res)
        User.stubs(:search).returns(@users)
        NetworkAsset.stubs(:search).returns(@assets)
      end

      should "be tracked with results" do
        get '/search/e'
        assert_response :success

        doc = last_tracking
        assert !doc.context.blank?

        assert_equal 'e', doc.context.query
        assert_equal [],  doc.context.tags
        assert_equal nil, doc.context.cat

        assert_equal @res.map(&:id),    doc.context.results.res
        assert_equal @users.map(&:id),  doc.context.results.users
        assert_equal @assets.map(&:id), doc.context.results.assets
      end

      should "be tracked with tags" do
        get '/search', :tag => 'a,b,c'
        assert_response :success

        doc = last_tracking
        assert !doc.context.blank?

        assert_equal '',        doc.context.query
        assert_equal %w(a b c), doc.context.tags
        assert_equal nil,       doc.context.cat
      end

      should "be tracked with tags and query" do
        get '/search/antani', :tag => 'd,e,f'
        assert_response :success

        doc = last_tracking
        assert !doc.context.blank?

        assert_equal 'antani',  doc.context.query
        assert_equal %w(d e f), doc.context.tags
        assert_equal nil,       doc.context.cat
      end

      should "be tracked with category" do
        cat = Factory.create(:res_category)
        get '/search', :cat => cat.shortcut
        assert_response :success

        doc = last_tracking
        assert !doc.context.blank?

        assert_equal '',     doc.context.query
        assert_equal [],     doc.context.tags
        assert_equal cat.id, doc.context.cat
      end

      should "be tracked with category and query" do
        cat = Factory.create(:res_category)
        get '/search/res/asd', :cat => cat.shortcut
        assert_response :success

        doc = last_tracking
        assert !doc.context.blank?

        assert_equal 'asd',  doc.context.query
        assert_equal [],     doc.context.tags
        assert_equal cat.id, doc.context.cat
      end
    end

    def last_tracking
      UsageTracker.database.view('basic/by_timestamp', :descending => true, :limit => 1).rows.first.value
    end
  end
end
