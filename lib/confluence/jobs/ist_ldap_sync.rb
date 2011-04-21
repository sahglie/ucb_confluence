
##
# Sync our confluence instance with LDAP so people in LDAP that are part
# of IST will be part of the ucb-ist group in confluence
#
module Confluence
  module Jobs
    class IstLdapSync
      
      IST_GROUP = 'ucb-ist'

      def initialize()
        @new_users = []
        @modified_users = []
      end
      
      ##
      # Run the job
      #
      def execute()
        @new_users.clear()
        @modified_users.clear()
        sync_ist_from_ldap()
        sync_ist_from_confluence()
        log_job()
      end
      
      ##
      # If the IST LDAP person is not in confluence, add them.  If they are in
      # confluence but not part of the IST_GROUP, give them membership.
      #
      def sync_ist_from_ldap()
        ist_people.each do |ldap_person|
          next unless eligible_for_confluence?(ldap_person)

          user = find_or_new_user(ldap_person.uid())

          if user.new_record?
            user.save()
            user.join_group(Confluence::User::DEFAULT_GROUP)
            @new_users << user        
          end
          
          unless user.groups.include?(IST_GROUP)
            user.join_group(IST_GROUP)
            @modified_users << user
          end
        end
      end
      
      ##
      # Remove a confluene user from the IST_GROUP if LDAP indicates they are
      # no longer part of IST
      #
      def sync_ist_from_confluence()
        confluence_user_names.each do |name|
          next if name == "conflusa"      
          
          ldap_person = find_in_ldap(name)
          next if ldap_person.nil?
          
          if !in_ist?(ldap_person)
            user = find_in_confluence(name)
            next if user.nil?
            user.leave_group(IST_GROUP)
            @modified_users << user        
          end
        end
      end
  
      def log_job()
        msg = "#{self.class.name}\n\n"
        
        msg.concat("Modified Users\n\n")
        @modified_users.each { |u| msg.concat(u) }
        msg.concat("\n")
        
        msg.concat("New Users\n\n")
        @new_users.each { |u| msg.concat(u) }
        msg.concat("\n")
        
        logger.info(msg)
      end
      
      def logger()
        Confluence.logger
      end
      
      ##
      # @return [Array<String>] confluence user names.
      #
      def confluence_user_names()
        Confluence::User.active.map(&:name)
      end
      
      ##
      # All of the people in IST.
      #
      # @return [Array<UCB::LDAP::Person>]
      #
      def ist_people(str = "UCBKL-AVCIS-VRIST-*")
        UCB::LDAP::Person.search(:filter => {"berkeleyedudeptunithierarchystring" => str})
      end

      ##
      # Retrieves the user if they already exist in Confluence.  Otherwise,
      # returns a new record that has not yet been persisted to Confluence.
      #
      # @param [String] the user's ldap uid
      # @return [Confluence::User] 
      #
      def find_or_new_user(ldap_uid)
        Confluence::User.find_or_new_from_ldap(ldap_uid)
      end
      
      ##
      # @param [String] user's confluence account name.
      # @return [Confluence::User, nil]
      #
      def find_in_confluence(name)
        Confluence::User.find_by_name(name)
      end
      
      ##
      # @param [String] user's ldap uid
      # @return [UCB::LDAP::Person, nil]
      #
      def find_in_ldap(ldap_uid)
        UCB::LDAP::Person.find_by_uid(ldap_uid)
      end
  
      def in_ist?(person)
        person.berkeleyEduDeptUnitHierarchyString.each do |str|
          return true if str =~ /UCBKL-AVCIS-VRIST-.*/
        end
        false
      end

      def eligible_for_confluence?(person)
        valid_affiliations = person.affiliations.inject([]) do |accum, aff|
          if aff =~ /AFFILIATE-TYPE.*(ALUMNUS|RETIREE|EXPIRED)/
            accum
          elsif aff =~ /AFFILIATE-TYPE.*/
            accum << aff
          end
          accum
        end
        
        person.employee? || !valid_affiliations.empty?
      end
    end
  end
end

