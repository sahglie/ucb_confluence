require 'pp'
require 'logger'
require 'ucb_ldap'
require 'xmlrpc/client'
require 'fileutils'

require 'confluence/conn'
require 'confluence/user'
require 'confluence/group'
require 'confluence/config'

require 'confluence/jobs/ist_ldap_sync'
require 'confluence/jobs/disable_expired_users'


module Confluence
  ROOT =  File.expand_path(File.dirname(__FILE__) + '/../')

  class << self
    
    def conn()
      unless @conn
        @conn = Confluence::Conn.new(config())
      end
      @conn
    end

    def config()
      unless @config
        @config = Confluence::Config.new()
        Confluence.logger.debug(@config.inspect())
      end
      @config
    end

    def config=(conf)
      @config = conf
    end
    
    def logger()
      unless @logger
        @logger = Logger.new("#{config.home()}/log/ucb_confluence.log")
        @logger.level = Logger::DEBUG
      end
      @logger
    end

    def logger=(logger)
      @logger = logger
    end
    
    def root()
      ROOT
    end
  end
end

