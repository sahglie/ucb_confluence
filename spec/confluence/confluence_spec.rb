require File.dirname(__FILE__) + '/../spec_helper'


describe Confluence do
  before(:all) do
    Confluence.config = Confluence::Config.new("#{Confluence.root()}/config/config.yml")
  end
  
  
  it "should initialize" do
    Confluence.conn.should be_a(Confluence::Conn)
  end
  
  it "should set ROOT" do
    File.expand_path(File.dirname(__FILE__) + '/../../').should == Confluence.root()
  end

  it "should configure logging" do
    Confluence.logger.should_not be_nil
  end
end
