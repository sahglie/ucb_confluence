require File.dirname(__FILE__) + '/../spec_helper'


describe Confluence::Config do
  before(:all) do
    @config_yml = "#{Confluence.root()}/config/config.yml"
  end

  
  it "should load its configuration" do
    config = Confluence::Config.new(@config_yml)
    config[:server_url].should match(/http/)
    config[:ldap_url].should match(/ldap/)
    config[:username].should_not be_nil
    config[:password].should_not be_nil
    config[:user_default_password].should_not be_nil
  end
end
