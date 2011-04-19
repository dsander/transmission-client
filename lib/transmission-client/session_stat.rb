module Transmission  
  class SessionStat
    ATTRIBUTES = ['activeTorrentCount', 'downloadSpeed', 'pausedTorrentCount', 'torrentCount', 'uploadSpeed', 'cumulative-stats', 'current-stats']

    attr_reader :attributes

    def initialize(attributes)
      @attributes = attributes
    end

    def method_missing(m, *args, &block)
      m = m.to_s.gsub('_','-')
      if ATTRIBUTES.include? m
        return @attributes[m]
      else m[-1..-1] == '='
        raise "Invalid Attribute."
      end
    end
  end
end
