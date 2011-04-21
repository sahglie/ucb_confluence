module Confluence
  class Conn
    
    def initialize(config)
      @config = config
      server = XMLRPC::Client.new2(@config[:server_url])
      @conn = server.proxy("confluence1")
      @token = "12345"
      do_connect()
    end

    def method_missing(method_name, *args)
      begin
        @conn.send(method_name, *([@token] + args))
      rescue XMLRPC::FaultException => e
        if (e.faultString.include?("InvalidSessionException"))
          do_connect
          retry
        else
          raise(e.faultString)
        end
      end
    end

    def do_connect()
      @token = @conn.login(@config[:username], @config[:password])
    rescue XMLRPC::FaultException => e
      raise(e.faultString)
    rescue => e
      Confluence.logger.debug("#{e.class}: #{e.message}")
      raise(e)
    end
    
  end
end
