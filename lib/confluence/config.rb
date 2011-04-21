module Confluence
  class Config
    
    def initialize(config_file = "#{home()}/config.yml")

      init_home_dir()
      conf = YAML.load_file(config_file)
      
      @conf = {}
      @conf[:server_url] = conf['server_url']
      @conf[:server_url].concat("/rpc/xmlrpc") unless @conf[:server_url][-11..-1] == "/rpc/xmlrpc"
      @conf[:ldap_url] = conf['ldap_url']
      @conf[:username] = conf['username'].to_s
      @conf[:password] = conf['password'].to_s      
      @conf[:user_default_password] = conf['user_default_password'].to_s
    end

    def [](key)
      @conf[key.to_sym]
    end

    def home()
      "#{ENV['HOME']}/.ucb_confluence"
    end
    
    def init_home_dir()
      FileUtils.mkdir(home()) unless File.exists?(home())
      FileUtils.mkdir("#{home()}/log") unless File.exists?("#{home()}/log")
    end
    
  end
end
