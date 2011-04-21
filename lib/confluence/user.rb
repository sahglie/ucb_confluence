module Confluence
  class User
    DISABLED_SUFFIX = "(ACCOUNT DISABLED)"
    DEFAULT_GROUP = 'confluence-users'
    VALID_ATTRS = [:name, :fullname, :email]
    
    class LdapPersonNotFound < StandardError; end;
    
    attr_accessor :name, :fullname, :email
    
    ##
    # Unrecognized attributes are ignored
    #
    def initialize(attrs = {})
      @new_record = true
      @errors = []
      VALID_ATTRS.each do |attr|
        self.send("#{attr}=", attrs[attr] || attrs[attr.to_s])
      end
    end
    
    def self.new_from_ldap(ldap_person)
      @new_record = true
      @errors = []
      self.new({
        :name => ldap_person.uid,        
        :fullname => "#{ldap_person.first_name} + #{ldap_person.last_name}",
        :email => ldap_person.email || "test@berkeley.edu"
      })
    end
    
    ##
    # Lets confluence XML-RPC access this object as if it was a Hash.
    # returns nil if key is not in VALID_ATTRS
    #
    def [](key)
      self.send(key) if VALID_ATTRS.include?(key.to_sym)
    end

    ##
    # Name can only be set if the user has not yet been saved to confluence
    # users table.  Once they have been saved, the name is immutable.  This is
    # a restriction enforced by Confluence's API.
    #
    def name=(n)
      @name = n if new_record?
    end
    
    ##
    # Predicate that determines if this [User] record has been persisted.
    #
    # @return [true, false] evaluates to true if the record has not been
    # persisted, evaluates to false if it has not been persisted.
    #
    def new_record?
      @new_record
    end
    
    def to_s()
      "name=#{name}, fullname=#{fullname}, email=#{email}"
    end
    
    ##
    # Creates a [Hash] representation of this user object.
    #
    # @example
    #   user.to_hash
    #   #=> {"name" => "runner", "fullname" => "Steven Hansen", "runner@b.e"}
    #
    # @return [Hash<String,String>]
    #
    def to_hash()
      {"name" => name, "fullname" => fullname, "email" => email}
    end

    ##
    # List of all groups this user has membership in.
    #
    # @return [Array<String>] names of all groups.
    #
    def groups()
      return [] if new_record?
      conn.getUserGroups(self.name)
    end

    ##
    # Gives user membership in a group.
    #
    # @param [String] the name of the group
    # @return [true, false] result of whether group membership was successful.
    #
    def join_group(grp)
      @errors.clear
      unless groups.include?(grp)
        conn.addUserToGroup(self.name, grp)
        logger.debug("User [#{self}] added to group: #{grp}")
        return true
      else
        @errors << "User is already in group: #{grp}"
        return false
      end
    rescue(RuntimeError) => e
      logger.debug(e.message)
      @errors << e.message
      return false
    end
    
    ##
    # Removes user from a group.
    #
    # @param [String] the name of the group
    # @return [true, false] result of whether removal from group was successful.
    #
    def leave_group(grp)
      @errors.clear
      if groups.include?(grp)
        conn.removeUserFromGroup(self.name, grp)
        logger.debug("User [#{self}] removed from group: #{grp}")
        return true
      else
        @errors << "User not in group: #{grp}"
        return false
      end
    rescue(RuntimeError) => e
      logger.debug(e.message)
      @errors << e.message
      return false
    end
    
    ##
    # Persists any changes to this user.  If the user record is new, a new record
    # is created.
    #
    # @return [true, false] result of whether operation was successful.
    #
    def save()
      @errors.clear
      if new_record?
        conn.addUser(self.to_hash, Confluence.config[:user_default_password])
        @new_record = false
      else
        conn.editUser(self.to_hash)
      end
      return true
    rescue(RuntimeError) => e
      logger.debug(e.message)
      @errors << e.message
      return false
    end
    
    ##
    # Deletes the user from Confluence.
    #
    # @return [true, false] result of whether operation was successful.
    #
    def delete()
      @errors.clear
      conn.removeUser(name.to_s)
      self.freeze
      return true
    rescue(RuntimeError) => e
      logger.debug(e.message)
      @errors << e.message
      return false
    end
    
    ##
    # Flags this user as disabled (inactive) and removes them from all
    # groups.  Update happens immediately.
    #
    # @return [true, false] true if the operation was successfull, otherwise
    # false
    #    
    def disable()
      @errors.clear
      if disabled?
        logger.debug("#{self} has already been disabled")
        return true
      end

      groups.each { |grp| leave_group(grp) }
      self.fullname = "#{self.fullname} #{DISABLED_SUFFIX}"
      result = self.save()
      logger.debug("Disabled user: #{self}")
      result
    end

    ##
    # Predicate indicating if the current user is disabled (inactive)
    #
    # @return [true, false]
    #    
    def disabled?
      fullname.include?(DISABLED_SUFFIX) && groups.empty?
    end

    def logger()
      self.class.logger
    end
    
    def conn()
      self.class.conn
    end
    
    ##
    # List of errors associated with this record.
    #
    # @return [Array<String>]
    #
    def errors()
      @errors ||= []
    end
    
    class << self
      def conn()
        Confluence.conn
      end
      
      def logger()
        Confluence.logger
      end

      ##
      # Finds an existing Confluence user by their name (which also happens
      # to be their ldap_uid).  If they do not exist in Confluence, we look
      # them up in LDAP and then add them to Confluence finally returning
      # the newly created user object.
      #
      def find_or_create_from_ldap(name)
        user = find_or_new_from_ldap(name)
        user.save if user.new_record?
        user
      end
      
      def find_or_new_from_ldap(name)
        if (u = find_by_name(name))
          return u
        elsif (p = UCB::LDAP::Person.find_by_uid(name)).nil?
          msg = "User not found in LDAP: #{name}"
          logger.debug(msg)
          raise(LdapPersonNotFound, msg)
        else
          self.new({
            :name => p.uid.to_s,
            :fullname => "#{p.first_name} + #{p.last_name}",
            :email => p.email || "test@berkeley.edu"
          })
        end
      end

      ##
      # Retrieves all users where their accoutns have been disabled.
      #
      # @return [Array<Confluence::User>]
      #
      def expired()
        self.all.select { |u| u[:fullname].include?("ACCOUNT DISABLED") }
      end

      ##
      # Retrieves all users where their accounts are currently enabled.
      #
      # @return [Array<Confluence::User>]
      #
      def active()
        self.all.reject { |u| u[:fullname].include?("ACCOUNT DISABLED") }
      end
      
      ##
      # Returns a list of all Confluence user names.
      #
      # @return [Array<String>] where each entry is the user's name
      # in Confluence.
      #
      def all_names()
        conn.getActiveUsers(true) 
      end

      ##
      # Retrieves all users, both expired and active.
      #
      # @return [Array<Confluence::User>]
      #
      def all()
        all_names.map { |name| find_by_name(name) }
      end
      
      ##
      # Finds a given Confluence user by their username.
      #
      # @param [String] the username.
      # @return [Confluence::User, nil] the found record, otherwise returns
      # nil.
      #
      def find_by_name(name)
        begin
          u = self.new(conn.getUser(name.to_s))
          u.instance_variable_set(:@new_record, false)
          u
        rescue(RuntimeError) => e
          logger.debug(e.message)
          return nil
        end
      end

      def exists?(name)
        conn.hasUser(name)
      end
    end
  end
end

