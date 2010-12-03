require 'usage_tracker/context'

module UsageTracker
  class Railtie < Rails::Railtie
    initializer 'usage_tracker.insert_into_action_controller' do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.instance_eval { include UsageTracker::Context }
      end
    end
  end
end
