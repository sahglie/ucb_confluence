require File.dirname(__FILE__) + '/../spec_helper'


describe Confluence::Group do
  before(:all) do
    Confluence.config = Confluence::Config.new("#{Confluence.root()}/config/config.yml")
    Confluence::Group.delete("atestgroup") if Confluence::Group.all.include?("atestgroup")
  end

  
  it "should get all groups" do
    Confluence::Group.all.should_not be_empty
  end
  
  context "create()" do
    it "should create a group" do
      Confluence::Group.all.should_not include("atestgroup")
      Confluence::Group.create("atestgroup").should be_true
      Confluence::Group.all.should include("atestgroup")
      Confluence::Group.delete("atestgroup")
      Confluence::Group.all.should_not include("atestgroup")    
    end

    it "should not create a group if the group already exists" do
      Confluence::Group.create("atestgroup")
      Confluence::Group.all.should include("atestgroup")
      Confluence::Group.create("atestgroup").should be_false
      Confluence::Group.delete("atestgroup")
    end
  end
  
  context "delete()" do
    it "should delete a group" do
      Confluence::Group.create("atestgroup")
      Confluence::Group.all.should include("atestgroup")
      Confluence::Group.delete("atestgroup").should be_true
      Confluence::Group.all.should_not include("atestgroup")
    end

    it "should not delete a group if the group does not exist" do
      Confluence::Group.all.should_not include("atestgroup")
      Confluence::Group.delete("atestgroup").should be_false
    end        
  end
end
