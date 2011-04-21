module Transmission
  class Client
    def on_download_finished(&blk); @on_download_finished = blk; callback_initialized; end
    def on_torrent_added(&blk); @on_torrent_added = blk; callback_initialized; end
    def on_torrent_stopped(&blk); @on_torrent_stopped = blk; callback_initialized; end
    def on_torrent_started(&blk); @on_torrent_started = blk; callback_initialized; end
    def on_torrent_removed(&blk); @on_torrent_removed = blk; callback_initialized; end
    
    def initialize(host='localhost',port=9091, username = nil, password = nil)
      @connection = Connection.new(host, port, username, password)
      @torrents = nil
    end
    
    def start_all &cb
      @connection.send('torrent-start')
    end
    
    def start(id)
      @connection.send('torrent-start', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop(id)
      @connection.send('torrent-stop', {'ids' => id.class == Array ? id : [id]})
    end
    
    def stop_all &cb
      @connection.send('torrent-stop')
    end
    
    def remove(id, delete_data = false)
      @connection.send('torrent-remove', {'ids' => id.class == Array ? id : [id], 'delete-local-data' => delete_data })
    end
    
    def remove_all(delete_data = false)
      @connection.send('torrent-remove', {'delete-local-data' => delete_data })
    end

    def add_tracker(id, announce = 'http://retracker.local/announce')
      @connection.send('torrent-set', {'ids' => id.class == Array ? id : [id], 'trackerAdd' => announce.is_a?(Array) ? announce : [announce] })
    end

    def get_trackers(id)
      @connection.request('torrent-get', {'ids' => id.is_a?(Array) ? id : [id], 'fields' => ['trackers'] }) do |resp|
        yield resp
      end
    end

    def add_torrent(a)
      if a['filename'].nil? && a['metainfo'].nil?
        raise "You need to provide either a 'filename' or 'metainfo'."
      end
      @connection.send('torrent-add', a)
    end
    
    def add_torrent_by_file(filename)
      add_torrent({'filename' => filename})
    end
    
    def add_torrent_by_data(data)
      add_torrent({'metainfo' => data})
    end


    #TODO handler for resp['status'] != 'success'
    def session
      @connection.request('session-get') do |resp|
        if resp == :connection_error
          yield :connection_error
        else
          yield Session.new resp
        end
      end
    end
    
    def session_stat
      @connection.request('session-stats') { |resp| yield SessionStat.new resp }
    end
    
    #TODO handler for resp['status'] != 'success'
    # options = { 'fields' => ['id'], 'ids' => [1,4,6] }
    def torrents(options = {})
      options = { 'fields' => options } if options.is_a? Array
      params = { 'fields' => Transmission::Torrent::ATTRIBUTES}.merge options
      @connection.request('torrent-get', params) { |resp|
        if resp == :connection_error
          yield :connection_error
        else
          torrs = []
          resp['torrents'].each do |t|
            torrs << Torrent.new(t, @connection)
          end
          yield torrs
        end
      }
    end
    
    private
    def callback_initialized
      return if @torrent_poller
      @torrent_poller = EM.add_periodic_timer(1) do
        updated_torrents = {}
        self.torrents do |tors|
          tors.each do |torrent|
            updated_torrents[torrent.id] = torrent
          end
          compare_torrent_status updated_torrents
          @torrents = updated_torrents.dup
        end
        
        
      end
    end
    
    def compare_torrent_status updated_torrents
      return false unless @torrents
      updated_torrents.each_pair do |id, t|
        old = @torrents[t.id] if @torrents[t.id]
        if old == nil
          @on_torrent_started.call t if @on_torrent_started
        elsif old.downloading? && t.seeding?
          @on_download_finished.call t if @on_download_finished
        elsif old.stopped? && !t.stopped?
          @on_torrent_started.call t if @on_torrent_started
        elsif !old.stopped? && t.stopped?
          @on_torrent_stopped.call t if @on_torrent_stopped
        end
        @torrents.delete t.id
      end
      if @torrents.length > 0 && @on_torrent_removed
        @torrents.values.each do |t|
          @on_torrent_removed.call t    
        end
      end  
    end 
  end
end