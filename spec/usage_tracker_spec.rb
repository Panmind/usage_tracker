require File.join( File.dirname( File.expand_path(__FILE__) )  , 'spec_helper' )  

require 'usage_tracker'
require 'em-spec/rspec'
require 'usage_tracker/reactor'

describe UsageTracker::Reactor do 
  include EM::Spec

  # Not a great test, ensures the run! method does not crash, at least
  it "should run the reactor" do
    EM.run do 
      UsageTracker.run!
      done
    end
  end

  it "should accept valid keys" do
    EM.run do 
      UsageTracker.run!
      UDPSocket.open do |sock|
        sock.connect(UsageTracker.settings.host, UsageTracker.settings.port.to_i)
        sock.write_nonblock({:env => 'env!', :duration => '10.2', :status => '200'}.to_json) 
      end
      done
    end
  end

  
end







