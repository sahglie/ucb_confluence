require File.dirname(__FILE__) + '/../spec_helper'


describe Confluence do
  it "should initialize" do
    ENV['CONFLUENCE_ENV'] = 'test'
    Confluence.conn.should be_a(Confluence::Conn)
    Confluence.env.should == :test
  end
  
  it "should set ROOT" do
    File.expand_path(File.dirname(__FILE__) + '/../../').should == Confluence.root()
  end

  it "should configure logging" do
    Confluence.logger.should_not be_nil
  end
end
