
##
# Disables a user's Confluence account if they are considered expired.
#
module Confluence
  module Jobs
    class DisableExpiredUsers
      
      def initialize()
        @disabled_users = []
      end
      
      ##
      # Run the job
      #
      def execute()
        @disabled_users.clear()
        disable_expired_users()
        log_job()
      end
      
      ##
      # Disables any users that are expired in LDAP or are no longer in LDAP.
      #
      def disable_expired_users()
        confluence_user_names.each do |name|
          next if name == "conflusa"      
          ldap_person = find_in_ldap(name)
          
          if ldap_person.nil? || !eligible_for_confluence?(ldap_person)
            user = find_in_confluence(name)
            user.disable()
            @disabled_users << user        
          end
        end
      end
  
      def log_job()
        msg = "#{self.class.name}\n\n"
        msg.concat("Disabled the following Users:\n\n")
        @disabled_users.each { |u| msg.concat(u) }
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

