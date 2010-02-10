module Transmission
  class Client
    def initialize(host='localhost',port=9091, username = nil, password = nil)
      Connection.init(host, port, username, password)
    end
    
    def start_all &cb
      Connection.send('torrent-start')
    end
    
    def start(id)
      Connection.send('torrent-start', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop(id)
      Connection.send('torrent-stop', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop_all &cb
      Connection.send('torrent-stop')
    end
    
    def remove(id, delete_data = false)
      Connection.send('torrent-remove', {'ids' => id.class == Array ? id : [id], 'delete-local-data' => delete_data })
    end
    
    def remove_all(delete_data = false)
      Connection.send('torrent-remove', {'delete-local-data' => delete_data })
    end

    def add_torrent(a)
      if a['filename'].nil? && a['metainfo'].nil?
        raise "You need to provide either a 'filename' or 'metainfo'."
      end
      Connection.send('torrent-add', a)
    end
    
    def add_torrent_by_file(filename)
      add_torrent({'filename' => filename})
    end
    
    def add_torrent_by_data(data)
      add_torrent({'metainfo' => data})
    end
    
    def session
      Connection.request('session-get') { |resp| yield Session.new resp }
    end
    
  	def torrents(fields = nil)
  	  torrs = []
  	  Connection.request('torrent-get', {'fields' => fields ? fields : Transmission::Torrent::ATTRIBUTES}) { |resp| 
  	    resp['torrents'].each do |t|
  	      torrs << Torrent.new(t)
		    end
		    yield torrs
	    }
    end
  end
end