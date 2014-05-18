module Transmission
  class Connection
    def initialize(host, port, username = nil, password = nil)
      @host = host
      @port = port
      @header = username.nil? ? {} : {'authorization' => [username, password]}
      @uri = URI.parse("http://#{@host}:#{@port}/transmission/rpc")
    end

    def request(method, attributes={})
      @conn = EventMachine::HttpRequest.new(@uri)
      req = @conn.post(:body => build_json(method, attributes), :head => @header)
      req.callback {
        case req.response_header.status
          when 401
            raise SecurityError, 'The client was not able to authenticate, is your username or password wrong?'
          when 409 #&& @header['x-transmission-session-id'].nil?
            @header['x-transmission-session-id'] = req.response_header['X_TRANSMISSION_SESSION_ID']
            request(method, attributes) do |resp|
              yield resp
            end
          when 200
            resp = JSON.parse(req.response)
            if resp["result"] == 'success'
              yield resp['arguments']
            else
              yield resp
            end
        end
      }
      req.errback {
        yield :connection_error
      }
    end

    def send(method, attributes={})
      request(method, attributes) do |resp|
        yield resp if block_given?
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
