require 'ucb_ldap'
require 'logger'
require 'confluence'
require 'pp'


##
# Sync our confluence instance with LDAP so people in LDAP that are part
# of IST will be part of the ucb-ist group in confluence
#
class LdapConfluenceSync
  User = Struct.new("User", :name, :fullname, :email)
  
  IST_GROUP = 'ucb-ist'
  DEFAULT_GROUP = 'confluence-users'
  DEACTIVATED_SUFFIX = "(ACCOUNT DISABLED)"
  
  def initialize(_env)
    @env = _env
    config = YAML.load_file('./config.yml')[@env]
    @server_url = config['server_url']
    @admin_username = config['admin_username'].to_s
    @admin_password = config['admin_password']
    @default_password = config['default_password']
    @ldap_host = config['ldap_host']

    @logger = Logger.new("ldap_confluence_sync-#{@env}.log")
    @logger.level = Logger::INFO

    UCB::LDAP.host = @ldap_host
    
    @rpc = Confluence::Server.new(@server_url)
    @rpc.login(@admin_username, @admin_password)
    @new_users = []
    @deactivated_users = []
    @modified_users = []
  end
  
  def ldap_people_for_hierarchy_str(_str = "UCBKL-AVCIS-VRIST-*")
    UCB::LDAP::Person.search(:filter => {"berkeleyedudeptunithierarchystring" => _str})
  end
  
  #####
  # Confluence considers a user 'deactivated' if they do not belong to any groups
  #
  def deactivate_confluence_user(_user)
    if deactivated_confluence_user?(_user)
      msg = "#{_user.inspect} already has already been deactivated"
      @logger.debug("#{msg}")
      return
    end
    
    @rpc.getUserGroups(_user.name).each { |grp| @rpc.removeUserFromGroup(_user.name, grp) }
    
    @deactivated_users << _user

    msg = "Deactivating expired user: [#{_user.fullname}, #{_user.name}]"
    puts msg
    @logger.info(msg)

    _user.fullname = "#{_user.fullname} #{DEACTIVATED_SUFFIX}"
    @rpc.editUser(_user)
  end
  
  def confluence_user?(_user)
    begin
      @rpc.getUser(_user.name)
      return true
    rescue(RuntimeError)
      return false
    end
  end
  
  def deactivated_confluence_user?(_user)
    begin
      user = {}
      user = @rpc.getUser(_user.name)
      
      groups = []
      groups = @rpc.getUserGroups(_user.name)
      
      (user["fullname"].include?(DEACTIVATED_SUFFIX) && groups.empty?) ? true : false
    rescue(RuntimeError)
      return false
    end
  end
  
  def add_new_confluence_user(_user)
    @rpc.addUser(_user, @default_password)
    @new_users << _user
    @logger.info("New user [#{_user.fullname}, #{_user.name}] was added to confluence.")
  end

  def build_confluence_user(_obj)
    if _obj.instance_of?(Hash)
      name = _obj["name"]
      email = _obj["email"] || "test@berkeley.edu"
      fullname = _obj["fullname"]
    else
      name = _obj.uid.to_s
      email = _obj.email || "test@berkeley.edu"
      fullname =  "#{_obj.first_name} #{_obj.last_name}"
    end
    User.new(name, fullname, email)
  end

  def add_user_to_group(_user, _group)
    if !@rpc.getUserGroups(_user.name).include?(_group)
      @rpc.addUserToGroup(_user.name, _group)
      @modified_users << _user
      @logger.info("User [#{_user.fullname}, #{_user.name}] was added to group: #{_group}")
    end
  end
  
  def remove_user_from_group(_user, _group)
    if !@rpc.getUserGroups(_user.name).include?(_group)
      @rpc.removeUserFromGroup(_user.name, _group)
      @modified_users << _user
      @logger.info("User [#{_user.fullname}, #{_user.name}] was removed from group: #{_group}")
    end
  end
  
  #####
  # * If the IST LDAP person is now expired and has a confluence account,
  #   deactivate their confluence account.
  # * If the IST LDAP person has a confluence account, but they are not part
  #   of the IST_GROUP, add them.
  # * If the IST LDAP person does not have a confluence account, create their
  #   account
  #
  def do_sync_ist_from_ldap()
    ldap_people_for_hierarchy_str("UCBKL-AVCIS-VRIST-*").each do |ldap_person|
      user = build_confluence_user(ldap_person)

      if confluence_user?(user)
        if !ldap_person.eligible_for_confluence?
          deactivate_confluence_user(user)
        else
          add_user_to_group(user, IST_GROUP)
          add_user_to_group(user, DEFAULT_GROUP)
        end
      elsif !confluence_user?(user) && ldap_person.eligible_for_confluence?
        add_new_confluence_user(user)
        add_user_to_group(user, IST_GROUP)        
        add_user_to_group(user, DEFAULT_GROUP)                
      end
    end
  end
  
  #####
  # * Deactivates any confluence users that are no longer in LDAP
  # * Removes a confluene user from the IST_GROUP if according to LDAP
  #   they are no longer part of IST
  #
  def do_sync_ist_from_confluence()
    @rpc.getActiveUsers(true).each do |uid|
      remote_user = @rpc.getUser(uid)
      user = build_confluence_user(remote_user)

      # Skip admin
      next if user.name == "conflusa"
      
      ldap_person = UCB::LDAP::Person.find_by_uid(uid)
      if ldap_person.nil? || !ldap_person.eligible_for_confluence?
        deactivate_confluence_user(user)
      elsif !ldap_person.in_ist?
        if @rpc.getUserGroups(user.name).include?(IST_GROUP)
          remove_user_from_group(user, IST_GROUP)
        end
      end
    end
  end
  
  #####
  # Run the sync code
  #
  def run
    @modified_users.clear()
    @new_users.clear()
    @deactivated_users.clear()

    if !@rpc.hasGroup(IST_GROUP)
      @rpc.addGroup(IST_GROUP)
    end
    
    do_sync_ist_from_ldap()
    do_sync_ist_from_confluence()
    @logger.info("Sync completed for [#{@env}] environment")

    send_email_notification()
  end

  def send_email_notification()
    formatter = lambda { |u| "name: #{u.name}, fullname: #{u.fullname}, email: #{u.email}\n" } 
    
    msg = "LDAP Confluence Sync Report - #{@env}\n\n"
    
    msg.concat("Modified Users\n\n")
    @modified_users.each do |u|
      msg.concat(formatter.call(u))
    end
    msg.concat("\n")
    
    msg.concat("New Users\n\n")
    @new_users.each do |u|
      msg.concat(formatter.call(u))
    end
    msg.concat("\n")
    
    msg.concat("Deactivated Users\n\n")
    @deactivated_users.each do |u|
      msg.concat(formatter.call(u))
    end

    puts msg
  end
end


# Customizations of this class for this script only
class UCB::LDAP::Person
  def valid_affiliations
    affiliations.inject([]) do |accum, aff|
      if aff =~ /AFFILIATE-TYPE.*(ALUMNUS|RETIREE|EXPIRED)/
        accum
      elsif aff =~ /AFFILIATE-TYPE.*/
        accum << aff
      end
      accum
    end
  end

  def valid_affiliate?
    !valid_affiliations.empty?
  end

  def eligible_for_confluence?
    self.employee? || self.valid_affiliate?
  end

  def in_ist?
    self.berkeleyEduDeptUnitHierarchyString.each do |str|
      return true if str =~ /UCBKL-AVCIS-VRIST-.*/
    end
    false
  end
end


# Run the script
env_option = ARGV[0]
if env_option.nil? || env_option !~ /^--env=(dev|qa|prod)$/
  puts "Usage: sync_ist_ldap_people.rb --env=[dev|qa|prod]"
  exit(1)
else
  env = env_option.split("=")[1]
  puts "Running sync for [#{env}] environment"
  sync = LdapConfluenceSync.new(env)
  sync.run()
  puts "Sync completed for [#{env}] environment"
  exit(0)
end
