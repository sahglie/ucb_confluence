require File.dirname(__FILE__) + '/../spec_helper'

describe Confluence::Conn do
  it "should connect to confluence" do
    config = Confluence::Config.new(:test)
    Confluence::Conn.new(config).should be_a(Confluence::Conn)
  end
end
