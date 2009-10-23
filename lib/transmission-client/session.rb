module Transmission  
  class Session
    ATTRIBUTES = ['alt-speed-down', 'alt-speed-enabled', 'alt-speed-time-begin', 'alt-speed-time-enabled', 'alt-speed-time-end', 'alt-speed-time-day', 'alt-speed-up', 'blocklist-enabled', 'blocklist-size', 'download-dir', 'dht-enabled', 'encryption', 'incomplete-dir', 'incomplete-dir-enabled', 'peer-limit-global', 'peer-limit-per-torrent', 'pex-enabled', 'peer-port', 'peer-port-random-on-start', 'port-forwarding-enabled', 'rpc-version', 'rpc-version-minimum', 'seedRatioLimit', 'seedRatioLimited', 'speed-limit-down', 'speed-limit-down-enabled', 'speed-limit-up', 'speed-limit-up-enabled', 'version']
    def initialize(attributes)
      @attributes = attributes
    end

    def method_missing(m, *args, &block)
      m = m.to_s.gsub('_','-')
      if ATTRIBUTES.include? m
        return @attributes[m]
      elsif m[-1..-1] == '='
        if ["blocklist-size","rpc-version", "rpc-version-minimum", "version"].include? m[0..-2]
          raise "Invalid Attribute."
        end
        return Connection.instance.send('session-set', {m[0..-2] => args.first})
      else
        raise "Invalid Attribute."
      end
    end
  end
end