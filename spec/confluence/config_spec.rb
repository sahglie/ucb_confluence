require File.dirname(__FILE__) + '/../spec_helper'


describe Confluence::Config do
  it "should load its configuration" do
    config = Confluence::Config.new(:test)
    config[:env].should == :test
    config[:server_url].should match(/http/)
    config[:ldap_url].should match(/ldap/)
    config[:username].should_not be_nil
    config[:password].should_not be_nil
    config[:user_default_password].should_not be_nil
  end

  it "should recognize valid environments" do
    Confluence::Config::VALID_ENVS.each { |e| lambda { Confluence::Config.new(e) }.should_not raise_error }
    lambda { Confluence::Config.new(:poo) }.should raise_error
  end
  
end
