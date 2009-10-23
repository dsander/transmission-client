module Transmission
  class Client
    def initialize(host='localhost',port=9091)
      Connection.instance.init(host, port)
    end
    
    def start_all
      Connection.instance.send('torrent-start')
    end
    
    def start(id)
      Connection.instance.send('torrent-start', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop(id)
      Connection.instance.send('torrent-stop', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop_all
      Connection.instance.send('torrent-stop')
    end
    
    def remove(id, delete_data = false)
      Connection.instance.send('torrent-remove', {'ids' => id.class == Array ? id : [id], 'delete-local-data' => delete_data })
    end
    
    def remove_all(delete_data = false)
      Connection.instance.send('torrent-remove', {'delete-local-data' => delete_data })
    end

    def add_torrent(a)
      if a['filename'].nil? && a['metainfo'].nil?
        raise "You need to provide either a 'filename' or 'metainfo'."
      end
      Connection.instance.send('torrent-add', a)
    end
    
    def add_torrent_by_file(filename)
      add_torrent({'filename' => filename})
    end
    
    def add_torrent_by_data(data)
      add_torrent({'metainfo' => data})
    end
    
    def session
      Session.new Connection.instance.request('session-get')
    end
    
  	def torrents(fields = nil)
  	  torrs = []
  	  Connection.instance.request('torrent-get', {'fields' => fields ? fields : Transmission::Torrent::ATTRIBUTES})['torrents'].each do |t|
  	    torrs << Torrent.new(t)
		  end
		  torrs
    end
  end
end