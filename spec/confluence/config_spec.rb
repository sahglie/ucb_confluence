require File.dirname(__FILE__) + '/../spec_helper'

describe Confluence::Config do
  it "should load its configuration" do
    config = Confluence::Config.new(:test)
    config[:env].should == :test
    config[:server_url].should == "server_url_test/rpc/xmlrpc"
    config[:ldap_url].should == "ldap_url_test"
    config[:username].should == "username_test"
    config[:password].should == "password_test"
    config[:user_default_password].should == "user_default_password_test"        
  end

  it "should recognize valid environments" do
    Confluence::Config::VALID_ENVS.each { |e| lambda { Confluence::Config.new(e) }.should_not raise_error }
    lambda { Confluence::Config.new(:poo) }.should raise_error
  end
  
end
