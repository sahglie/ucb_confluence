require 'pp'
require 'logger'
require 'ucb_ldap'
require 'confluence/conn'
require 'confluence/user'
require 'confluence/group'
require 'confluence/config'


module Confluence
  ROOT =  File.expand_path(File.dirname(__FILE__) + '/../')

  class << self
    def env
      config[:env]
    end
    
    def conn
      @conn ||= Confluence::Conn.new(config)
    end

    def config
      @config ||= Confluence::Config.new(ENV['CONFLUENCE_ENV'] || CONFLUENCE_ENV || :dev)
    end

    def logger
      unless @logger
        @logger = Logger.new("#{ROOT}/log/confluence-#{config[:env]}.log")
        @logger.level = Logger::DEBUG
      end
      @logger
    end

    def root
      ROOT
    end
  end
end

