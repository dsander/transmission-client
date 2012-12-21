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
      @connection.send('torrent-start') do |resp|
        yield resp if block_given?
      end
    end

    def start(id)
      @connection.send('torrent-start', {'ids' => [*id].map(&:to_i)}) do |resp|
        yield resp if block_given?
      end
    end

    def stop(id)
      @connection.send('torrent-stop', {'ids' => [*id].map(&:to_i)}) do |resp|
        yield resp if block_given?
      end
    end

    def stop_all &cb
      @connection.send('torrent-stop') do |resp|
        yield resp if block_given?
      end
    end

    def remove(id, delete_data = false)
      @connection.send('torrent-remove', {'ids' => [*id].map(&:to_i), 'delete-local-data' => delete_data }) do |resp|
        yield resp if block_given?
      end
    end

    def remove_all(delete_data = false)
      @connection.send('torrent-remove', {'delete-local-data' => delete_data }) do |resp|
        yield resp if block_given?
      end
    end

    def add_tracker(id, announce = 'http://retracker.local/announce')
      @connection.send('torrent-set', {'ids' => [*id].map(&:to_i), 'trackerAdd' => [*announce] }) do |resp|
        yield resp if block_given?
      end
    end

    def get_trackers(id)
      @connection.request('torrent-get', {'ids' => [*id].map(&:to_i), 'fields' => ['trackers'] }) do |resp|
        yield resp
      end
    end

    def add_torrent(a)
      if a['filename'].nil? && a['metainfo'].nil?
        raise "You need to provide either a 'filename' or 'metainfo'."
      end
      @connection.send('torrent-add', a) do |resp|
        yield resp if block_given?
      end
    end

    def add_torrent_by_file(filename)
      add_torrent({'filename' => filename}) do |resp|
        yield resp if block_given?
      end
    end

    def add_torrent_by_data(data)
      add_torrent({'metainfo' => data}) do |resp|
        yield resp if block_given?
      end
    end


    #TODO handler for resp['status'] != 'success'
    def session
      @connection.request('session-get') do |resp|
        if resp == :connection_error
          yield :connection_error
        else
          yield Session.new(resp)
        end
      end
    end

    def session_stat
      @connection.request('session-stats') { |resp| yield SessionStat.new(resp) }
    end

    def get_torrent(id, &block)
      self.torrents("ids" => [id.to_i]) do |torrents|
        block.call(torrents.first)
      end
    end

    #TODO handler for resp['status'] != 'success'
    # options = { 'fields' => ['id'], 'ids' => [1,4,6] }
    def torrents(options = {})
      options = { 'fields' => options } if options.is_a? Array
      params = { 'fields' => Transmission::Torrent::ATTRIBUTES}.merge options
      @connection.request('torrent-get', params) do |resp|
        if resp == :connection_error
          yield :connection_error
        else
          torrs = resp['torrents'].map { |t| Torrent.new(t, @connection) }
          yield torrs
        end
      end
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
          compare_torrent_status(@torrents, updated_torrents) if @torrents
          @torrents = updated_torrents
        end
      end
    end

    def compare_torrent_status(old_torrents, updated_torrents)
      old_torrents = old_torrents.dup
      updated_torrents.each_pair do |id, t|
        old = old_torrents[t.id]
        if old.nil?
          @on_torrent_started.call t if @on_torrent_started
        elsif old.downloading? && t.seeding?
          @on_download_finished.call t if @on_download_finished
        elsif old.stopped? && !t.stopped?
          @on_torrent_started.call t if @on_torrent_started
        elsif !old.stopped? && t.stopped?
          @on_torrent_stopped.call t if @on_torrent_stopped
        end
        old_torrents.delete t.id
      end
      if @on_torrent_removed
        old_torrents.values.each do |t|
          @on_torrent_removed.call t
        end
      end
    end
  end
end
