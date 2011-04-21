require File.dirname(__FILE__) + '/../../spec_helper'


describe Confluence::Jobs::DisableExpiredUsers do
  before(:all) do
    Confluence.config = Confluence::Config.new("#{Confluence.root()}/config/config.yml")    
  end
  
  before(:each) do
    @job = Confluence::Jobs::DisableExpiredUsers.new

    user = Confluence::User.find_by_name("n1")
    user.delete() if user
    
    @user = Confluence::User.new({:name => "n1", :fullname => "fn1", :email => "e@b.e"})
  end

  after(:each) do
    @user.delete()
  end
  

  context "#disable_expired_users()" do
    it "should disable users no longer in LDAP" do
      @user.save()      
      @job.stub!(:confluence_user_names).and_return([@user.name])
      @job.stub!(:find_in_confluence).and_return(@user)
      @job.stub!(:find_in_ldap).and_return(nil)
      
      @user.disabled?.should be_false
      @job.disable_expired_users()
      @user.disabled?.should be_true
      @user.groups.should be_empty
    end
    
    it "should disable user's LDAP considers expired" do
      ldap_user = mock("user1", {:ldap_uid => "n1", :first_name => "f1",
                                 :last_name => "l1", :email => "e1"})
      @user.save()      
      @job.stub!(:confluence_user_names).and_return([@user.name])
      @job.stub!(:find_in_confluence).and_return(@user)
      @job.stub!(:find_in_ldap).and_return(ldap_user)
      @job.stub!(:eligible_for_confluence?).and_return(false)
      
      @user.disabled?.should be_false
      @job.disable_expired_users()
      @user.disabled?.should be_true
      @user.groups.should be_empty
    end
  end
end
