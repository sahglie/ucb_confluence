require File.dirname(__FILE__) + '/../../spec_helper'


describe Confluence::Jobs::IstLdapSync do
  before(:each) do
    @job = Confluence::Jobs::IstLdapSync.new

    user = Confluence::User.find_by_name("n1")
    user.delete() if user
    
    @user = Confluence::User.new({:name => "n1", :fullname => "fn1", :email => "e@b.e"})
  end

  after(:each) do
    @user.delete()
  end
  

  context "#sync_ist_from_ldap()" do
    it "should add IST users found in LDAP to Confluence" do
      ldap_user = mock("user1", {:ldap_uid => "n1", :first_name => "f1",
                                 :last_name => "l1", :email => "e1"})
      @job.stub!(:ist_people).and_return([ldap_user])
      @job.stub!(:eligible_for_confluence?).and_return(true)
      @job.stub!(:find_or_new_user).and_return(@user)
      
      Confluence::User.exists?(@user.name).should be_false
      @job.sync_ist_from_ldap()
      @user = Confluence::User.find_by_name(@user.name)
      @user.groups.should have(2).records
      @user.groups.should include(Confluence::User::DEFAULT_GROUP)
      @user.groups.should include(Confluence::Jobs::IstLdapSync::IST_GROUP)
    end
    
    it "should give new IST users found in LDAP membership to the IST_GROUP" do
      ldap_user = mock("user1", {:ldap_uid => "n1", :first_name => "f1",
                                 :last_name => "l1", :email => "e1"})
      @job.stub!(:ist_people).and_return([ldap_user])
      @job.stub!(:eligible_for_confluence?).and_return(true)
      @job.stub!(:find_or_new_user).and_return(@user)

      
      @user.save()
      Confluence::User.exists?(@user.name).should be_true
      @user.groups.should have(1).record
      @user.groups.should include(Confluence::User::DEFAULT_GROUP)
      
      @job.sync_ist_from_ldap()
      @user.groups.should have(2).records
      @user.groups.should include(Confluence::User::DEFAULT_GROUP)
      @user.groups.should include(Confluence::Jobs::IstLdapSync::IST_GROUP)
    end
  end
  
  
  context "#sync_ist_from_confluence()" do
    it "should remove users from IST group" do
      ldap_user = mock("user1", {:ldap_uid => "n1", :first_name => "f1",
                                 :last_name => "l1", :email => "e1"})
      @user.save()      
      @job.stub!(:confluence_user_names).and_return([@user.name])
      @job.stub!(:find_in_confluence).and_return(@user)
      @job.stub!(:find_in_ldap).and_return(ldap_user)
      @job.stub!(:eligible_for_confluence?).and_return(true)
      @job.stub!(:in_ist?).and_return(false)
      
      @user.disabled?.should be_false
      @job.sync_ist_from_confluence()
      @user.groups.should have(1).record
      @user.groups.should_not include(Confluence::Jobs::IstLdapSync::IST_GROUP)
    end
  end  
end
