module Confluence
  class Group
    class << self
      ##
      # Retrieve a list of all groups in Confluence.
      #
      # @return [Array<String>] names of all groups in our Confluence instance.
      #
      def all()
        Confluence.conn.getGroups()
      end
      
      ##
      # Creates a new group in Confluence.
      #
      # @param [String] name of group to create.
      # @return [true, false] result of whether group was successfully created.
      #
      def create(name)
        if all.include?(name)
          return false
        else
          result = Confluence.conn.addGroup(name)
          Confluence.logger.debug("Created group: #{name}")
        end
        result
      end
      
      ##
      # Delete a group from Confluence.
      #
      # @param [String] name of group to delete.
      # @return [true, false] result of whether group was successfully deleted.
      #
      def delete(name)
        if all.include?(name)
          result = Confluence.conn.removeGroup(name, Confluence::User::DEFAULT_GROUP)
          Confluence.logger.debug("Deleted group: #{name}")
          return result
        else
          return false
        end
      end
      
      ##
      # Predicate that indicates whether a given group exists in Confluence
      #
      # @param [String] the group name.
      # @return [true,false]
      #
      def exists?(grp_name)
        all.include?(grp_name)
      end
    end
  end
end
