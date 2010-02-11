# transmission-client: A Transmission RPC Client

**Please note, with the current release i dropped support for the blocking api. Eventmachine is now required.**

The goal is to support all requests described in the Transmission [RPC Specifications](http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt).

## Installing
You need to have http://gemcutter.org in you gem sources. To add it you can execute either

	sudo gem install gemcutter
	sudo gem tumble

or

	sudo gem source -a http://gemcutter.org

To install transmission-client:

	sudo gem install transmission-client

## Usage
Get a list of torrents and print its file names:

	require 'transmission-client'

	EventMachine.run do
	  t = Transmission::Client.new
	  EM.add_periodic_timer(1) do
	    t.torrents do |torrents|
	      torrents.each do |tor|
	        puts tor.percentDone
	      end
	    end
	  end
	end
	
Authentication support (thanks hornairs):

	t = Transmission::Client.new('127.0.0.1', 9091, 'username', 'password')
	
Callbacks:

	EventMachine.run do
		t = Transmission::Client.new
	  	
	  	t.on_download_finished do |torrent|
	  	  puts "Wha torrent finished"
	  	end
	  	t.on_torrent_stopped do |torrent|
	  	  puts "Oooh torrent stopped"
	  	end
	  	t.on_torrent_started do |torrent|
	  	  puts "Torrent started."
	  	end
	  	t.on_torrent_removed do |torrent|
	  	  puts "Darn torrent deleted."
	  	end
	end
	
RDoc is still to be written, at the meantime have a look at the code to find out which methods are supported.
