require 'pp'
require 'logger'
require 'ucb_ldap'
require 'xmlrpc/client'

require 'confluence/conn'
require 'confluence/user'
require 'confluence/group'
require 'confluence/config'

require 'confluence/jobs/ist_ldap_sync'
require 'confluence/jobs/disable_expired_users'


module Confluence
  ROOT =  File.expand_path(File.dirname(__FILE__) + '/../')

  class << self
    def env()
      config[:env]
    end
    
    def conn()
      @conn ||= Confluence::Conn.new(config)
    end

    def config()
      env = CONFLUENCE_ENV if defined?(CONFLUENCE_ENV)
      @config ||= Confluence::Config.new(ENV['CONFLUENCE_ENV'] || env || :dev)
    end

    def logger()
      unless @logger
        @logger = Logger.new("#{root()}/log/confluence-#{CONFLUENCE_ENV}.log")
        @logger.level = Logger::DEBUG
      end
      @logger
    end

    def root()
      ROOT
    end
  end
end

