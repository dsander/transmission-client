module Transmission
  class Torrent
    ATTRIBUTES = ['activityDate', 'addedDate', 'bandwidthPriority', 'comment', 'corruptEver', 'creator', 'dateCreated', 'desiredAvailable', 'doneDate', 'downloadDir', 'downloadedEver', 'downloadLimit', 'downloadLimited', 'error', 'errorString', 'eta', 'hashString', 'haveUnchecked', 'haveValid', 'honorsSessionLimits', 'id', 'isPrivate', 'leftUntilDone', 'manualAnnounceTime', 'maxConnectedPeers', 'name', 'peer-limit', 'peersConnected', 'peersGettingFromUs', 'peersKnown', 'peersSendingToUs', 'percentDone', 'pieces', 'pieceCount', 'pieceSize', 'rateDownload', 'rateUpload', 'recheckProgress', 'seedRatioLimit', 'seedRatioMode', 'sizeWhenDone', 'startDate', 'status', 'swarmSpeed', 'totalSize', 'torrentFile', 'uploadedEver', 'uploadLimit', 'uploadLimited', 'uploadRatio', 'webseedsSendingToUs']
    ADV_ATTRIBUTES = ['files', 'fileStats', 'peers', 'peersFrom', 'priorities', 'trackers', 'trackerStats', 'wanted', 'webseeds']
    SETABLE_ATTRIBUTES = ['bandwidthPriority', 'downloadLimit', 'downloadLimited', 'files-wanted', 'files-unwanted', 'honorsSessionLimits', 'ids', 'location', 'peer-limit', 'priority-high', 'priority-low', 'priority-normal', 'seedRatioLimit', 'seedRatioMode', 'uploadLimit', 'uploadLimited']
    CHECK_WAIT = 1
    CHECK      = 2
    DOWNLOAD   = 4
    SEED       = 8
    STOPPED    = 16
    STATUS = {
	    0 => :stopped,
	    1 => :check_wait,
	    2 => :check,
	    3 => :download_wait,
	    4 => :download,
	    5 => :seed_wait,
	    6 => :seed
    }

    attr_reader :attributes

    def initialize(attributes, connection)
      @attributes = attributes
      @connection = connection
    end

    def to_json
      @attributes.to_json
    end

    def start
      @connection.send('torrent-start', {'ids' => @attributes['id']})
    end

    def stop
      @connection.send('torrent-stop', {'ids' => @attributes['id']})
    end

    def verify
      @connection.send('torrent-verify', {'ids' => @attributes['id']})
    end

    def reannounce
      @connection.send('torrent-reannounce', {'ids' => @attributes['id']})
    end

    def remove(delete_data = false)
      @connection.send('torrent-remove', {'ids' => @attributes['id'], 'delete-local-data' => delete_data })
    end

    def status_name
      STATUS[self.status] || :unknown
    end

    def downloading?
      self.status == DOWNLOAD
    end

    def stopped?
      self.status == STOPPED
    end

    def checking?
      self.status == CHECK || self.status == CHECK_WAIT
    end

    def seeding?
      self.status == SEED
    end

    def id
      @attributes['id']
    end

    def percent_done
      (method_missing(:percent_done) * 100).round
    end

    def eta_text
      secs = self.eta
      return "Done" if secs == -1
      [[60, :seconds], [60, :minutes], [24, :hours], [10000, :days]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}"
        end
      }.compact.reverse.join(' ')
    end

    def method_missing(m, *args, &block)
      m = m.to_s.split('_').inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
      if ATTRIBUTES.include? m
        return @attributes[m]
      elsif ADV_ATTRIBUTES.include? m
        raise "Attribute not yet supported."
      elsif m[-1..-1] == '='
        if SETABLE_ATTRIBUTES.include? m[0..-2]
          Connection.send('torrent-set', {'ids' => [@attributes['id']], m[0..-2] => args.first})
        else
          raise "Invalid Attribute."
        end
      else
        raise "Invalid Attribute."
      end
    end
  end # end class
end
