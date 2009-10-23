module Transmission
  class Connection
    include Singleton
    
    def init(host, port)
      @host = host
      @port = port
      uri = URI.parse("http://#{@host}:#{@port}")
      @conn = Net::HTTP.start(uri.host, uri.port)
      @header = {}
    end
    
    def request(method, attributes={})
      res = @conn.post('/transmission/rpc',build_json(method,attributes),@header) 
      if res.class == Net::HTTPConflict && @header['x-transmission-session-id'].nil?
        @header['x-transmission-session-id'] = res['x-transmission-session-id']
        request(method,attributes)
      elsif res.class == Net::HTTPOK
        resp = JSON.parse(res.body)
        if resp["result"] == 'success'
          #pp resp
          resp['arguments']
        else
          resp
        end
      end
    end
    
    def send(method, attributes={})
      request(method, attributes)['result'].nil?
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