module Confluence
  class Config
    VALID_ENVS = [:prod, :qa, :dev, :test]
    
    def initialize(env = :dev)
      env = env.to_sym
      raise(StandardError, "Invalid environment: #{env}") unless VALID_ENVS.include?(env)

      conf = YAML.load_file("#{Confluence.root}/config/config.yml")[env.to_s]
      @conf = {}
      @conf[:env] = env
      @conf[:server_url] = conf['server_url']
      @conf[:server_url].concat("/rpc/xmlrpc") unless @conf[:server_url][-11..-1] == "/rpc/xmlrpc"
      @conf[:ldap_url] = conf['ldap_url']
      @conf[:username] = conf['username'].to_s
      @conf[:password] = conf['password'].to_s      
      @conf[:user_default_password] = conf['user_default_password'].to_s
      Confluence.logger.debug(@conf.inspect)
    end

    def [](key)
      @conf[key.to_sym]
    end
  end
end
