require File.dirname(__FILE__) + '/../spec_helper'

describe Confluence::User do
  before :all do
    @user = Confluence::User.new({
      :name => "111111",
      :fullname => "Test Dude",
      :email => "test_dude@berkeley.edu"
    })
    @user.save
    
    @group = "test-group"
    Confluence::Group.create(@group)
  end

  after :all do
    @user.delete
    Confluence::Group.delete(@group)
  end
  
  it "should find all users" do
    Confluence::User.all.should_not be_empty
  end
  
  it "should initialize a user" do
    attrs = {:name => 'n', :fullname => 'fn', :email => 'e'}
    u = Confluence::User.new(attrs)
    u.name.should == 'n'
    u.fullname.should == 'fn'
    u.email.should == 'e'
    
    attrs = {'name' => 'n', 'fullname' => 'fn', 'email' => 'e'}
    u = Confluence::User.new(attrs)
    u.name.should == 'n'
    u.fullname.should == 'fn'
    u.email.should == 'e'
  end
  
  it "should find_by_name" do
    user = Confluence::User.find_by_name(@user.name)
    user.should be_a(Confluence::User)
    user.name.should == @user.name
    user.email.should == @user.email
    user.fullname.should == @user.fullname
  end
  
  it "should format when sent to_s" do
    user = Confluence::User.new(@user)
    user.to_s.should == "name=#{@user[:name]}, fullname=#{@user[:fullname]}, email=#{@user[:email]}"
  end

  it "should allow attributes to be access with Hash interface" do
    name = "111111"
    fullname = "Test Dude"
    email = "test_dude@berkeley.edu"
    @user[:name].should == name
    @user[:fullname].should == fullname
    @user[:email].should == email

    @user["name"].should == name
    @user["fullname"].should == fullname
    @user["email"].should == email

    @user[:bad_att].should == nil
  end

  it "should save a user's attributes" do
    # Confluence::User.find_by_name("name").delete
    Confluence::User.exists?("name").should_not be_true
    # New User
    user = Confluence::User.new({:name => "name", :email => "email", :fullname => "fullname"})
    user.should be_new_record
    
    user.save
    user.should_not be_new_record
    user = Confluence::User.find_by_name(user.name)
    user.should_not be_new_record
    user.email.should == "email"
    user.name.should == "name"
    user.fullname.should == "fullname"

    # Update attributes
    user.email = "emailx"
    user.fullname = "fullnamex"
    user.save

    user = Confluence::User.find_by_name(user.name)
    user.email.should == "emailx"
    user.name.should == "name"
    user.fullname.should == "fullnamex"
    user.delete
  end
end


describe Confluence::User, "ldap integration" do
  before :all do
    @ldap_user = "322586"
    u = Confluence::User.find_by_name(@ldap_user)
    u.delete if u
  end

  after :all do
    u = Confluence::User.find_by_name(@ldap_user)
    u.delete if u
  end

  it "should find_or_create_from_ldap" do
    Confluence::User.find_by_name(@ldap_user).should be_nil
    Confluence::User.find_or_create_from_ldap(@ldap_user)
    user = Confluence::User.find_by_name(@ldap_user)
    user.should_not be_nil
    UCB::LDAP::Person.should_not_receive(:find_by_uid)
    Confluence::User.find_or_create_from_ldap(@ldap_user).should_not be_nil
  end

  it "should raise error if find_or_create_from_ldap can't find user in ldap" do
    lambda { Confluence::User.find_or_create_from_ldap("q") }.should raise_error
  end
end


describe Confluence::User, "group management" do
  before :all do
    @user = Confluence::User.new({
      :name => "111111",
      :fullname => "Test Dude",
      :email => "test_dude@berkeley.edu"
    })
    @user.save
    
    @group = "test-group"
    Confluence::Group.create(@group)
  end

  after :all do
    @user.delete
    Confluence::Group.delete(@group)
  end
  
  it "should return a user's groups" do
    @user.should have(1).groups
  end

  it "should add a user to a group" do
    @user.groups.should_not include(@group)
    @user.join_group(@group).should be_true
    @user.groups.should include(@group)
    @user.leave_group(@group)
  end
  
  it "should gracefully handle bad groups names for join_group" do
    @user.join_group("badgroup").should be_false
  end

  context "leave_group()" do
    it "should be false if user is not in the group" do
      @user.leave_group("badgroup").should be_false
    end
    
    it "should be true if user is in the group" do
      @user.join_group(@group)
      @user.leave_group(@group).should be_true
      @user.groups.should_not include(@group)
    end
  end
end
