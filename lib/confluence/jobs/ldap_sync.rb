
##
# Sync our confluence instance with LDAP so people in LDAP that are part
# of IST will be part of the ucb-ist group in confluence
#
module Confluence
  module Jobs
    class LdapSync
      
      IST_GROUP = 'ucb-ist'
      
      def initialize()
        @new_users = []
        @deactivated_users = []
        @modified_users = []
      end
      
      ##
      # Run the job
      #
      def execute()
        @modified_users.clear()
        @new_users.clear()
        @deactivated_users.clear()

        sync_ist_from_ldap()
        sync_ist_from_confluence()
        logger.info("Sync completed for [#{Confluence.config[:env]}] environment")

        send_email_notification()
      end
      
      
      def logger()
        Confluence.logger
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
      # * If the IST LDAP person is not in confluence, add them.
      # * If the IST LDAP person is in confluence and not part of the IST_GROUP,
      #   give them membership
      # * If the IST LDAP person is now expired, disable their account.
      #
      def sync_ist_from_ldap()
        ist_people.each do |ldap_person|
          user = Confluence::User.find_or_new_from_ldap(ldap_person.ldap_uid)
          
          if user.new_record?
            user.save()
            user.join_group(Confluence::User::DEFAULT_GROUP)
            @new_users << user        
          end
          
          if eligible_for_confluence?(ldap_person)
            unless user.groups.include?(IST_GROUP)
              user.join_group(IST_GROUP)
              @modified_users << user
            end
          else
            user.disable()
            @deactivated_users << user
          end
        end
      end
      
      ##
      # * Deactivates any confluence users that are no longer in LDAP
      # * Remove a confluene user from the IST_GROUP if LDAP indicates they are no
      # longer part of IST
      #
      def sync_ist_from_confluence()
        Confluence::User.all.each do |name|
          next if name == "conflusa"      
          user = Confluence::User.find_by_name(name)
          ldap_person = UCB::LDAP::Person.find_by_uid(name)
          
          if ldap_person.nil? || !eligible_for_confluence?(ldap_person)
            user.disable()
            @deactivated_users << user        
          elsif !in_ist?(ldap_person)
            user.leave_group(IST_GROUP)
            @modified_users << user        
          end
        end
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
      
      def send_email_notification()
        msg = "LDAP Confluence Sync Report - #{Confluence.config[:env]}\n\n"
        
        msg.concat("Modified Users\n\n")
        @modified_users.each { |u| msg.concat(u) }
        msg.concat("\n")
        
        msg.concat("New Users\n\n")
        @new_users.each { |u| msg.concat(u) }
        msg.concat("\n")
        
        msg.concat("Deactivated Users\n\n")
        @deactivated_users.each { |u| msg.concat(u) }
        @logger.info
      end
      
    end
  end
end

