module Transmission
  class Connection
    include Singleton
    #include EM::Deferrable
    
    def init(host, port)
      @host = host
      @port = port
      uri = URI.parse("http://#{@host}:#{@port}/transmission/rpc")
      #@conn = Net::HTTP.start(uri.host, uri.port)
      @conn = EventMachine::HttpRequest.new(uri)
      @header = {} #{"Accept-Encoding" => "deflate"} deflate is broken somewhere
    end
    
    def request(method, attributes={}, &cb)
      req = @conn.post(:body => build_json(method,attributes), :head => @header )
      req.callback {
        if req.response_header.status == 409 #&& @header['x-transmission-session-id'].nil?
          @header['x-transmission-session-id'] = req.response_header['X_TRANSMISSION_SESSION_ID']
          request(method,attributes, &cb)
        elsif req.response_header.status == 200
          resp = JSON.parse(req.response)
          if resp["result"] == 'success'
            cb.call resp['arguments'] if cb
          else
            cb.call resp if cb
          end
        end
      }
      req.errback {
        puts 'errback'
        pp req
      }
    end
    
    def send(method, attributes={}, &cb)
      request(method, attributes) do |resp|
        cb.call resp if cb
      end
    end
    
    def build_json(method,attributes = {})
      if attributes.length == 0
        {'method' => method}.to_json
      else
       {'method' => method, 'arguments' => attributes }.to_json
      end
    end

  end
end