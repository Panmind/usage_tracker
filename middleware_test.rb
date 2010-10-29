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

    context 'a request from a guest' do
      should 'get tracked when successful' do
        assert_difference 'doc_count' do
          get '/'
          assert_response :success
        end

        doc = last_tracking
        assert_equal '/', doc.env.request_uri
        assert_equal nil, doc.user_id
        assert_equal 200, doc.status
        assert doc.duration > 0
      end

      should 'get tracked when not found' do
        get '/nonexistant'
        assert_response :not_found

        doc = last_tracking
        assert_equal '/nonexistant', doc.env.request_uri
        assert_equal 404,            doc.status
      end
    end

    context 'a request from a logged-in user' do
      setup do
        @user = Factory.create(:confirmed_user)
        post '/login', {:email => @user.email, :password => @user.password}, {'HTTPS' => 'on'}
        assert_redirected_to plain_root_url
      end

      should 'get tracked when successful' do
        assert_difference 'doc_count' do
          get '/_'
          assert_response :success
        end

        doc = last_tracking

        assert_equal '/_',     doc.env.request_uri
        assert_equal @user.id, doc.user_id
        assert_equal 200,      doc.status
      end

      should 'get tracked when not found' do
        get '/nonexistant'
        assert_response :not_found

        doc = last_tracking

        assert_equal '/nonexistant', doc.env.request_uri
        assert_equal @user.id,       doc.user_id
        assert_equal 404,            doc.status
        assert_equal false,          doc.xhr
      end

      should 'get tracked when failed' do
        xhr :get, '/projects/1/error', {}, {'HTTPS' => 'on'}
        assert_response :internal_server_error

        doc = last_tracking

        assert_equal '/projects/1/error', doc.env.request_uri
        assert_equal @user.id,            doc.user_id
        assert_equal 500,                 doc.status
        assert_equal true,                doc.xhr
        assert_equal `hostname`.strip,    doc.backend
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

    context "the middleware" do
      should "not wait for more than a second before aborting" do
        UDPSocket.expects(:open).once.yields(Class.new do
          def write_nonblock(*args); sleep 0.7 end
          def connect(*args)       ; sleep 0.7 end
        end.new)

        assert_no_difference 'doc_count' do
          get '/_'
          assert_response :success
        end
      end
    end

    def last_tracking
      sleep 0.3
      UsageTracker.database.view('basic/by_timestamp', :descending => true, :limit => 1).rows.first.value
    end

    def doc_count
      sleep 0.3
      UsageTracker.database.info['doc_count']
    end
  end
end
