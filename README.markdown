# tranmission-client: A Transmission RPC Client

The goal is to support all requests described in the Transmission [RPC Specifications](http://trac.transmissionbt.com/browser/trunk/doc/rpc-spec.txt).

## Installing
You need to have http://gemcutter.org in you gem sources. To add it you can execute either

	sudo gem install gemcutter
	sudo gem tumble`

or

	sudo gem source -a http://gemcutter.org

To install transmission-client:

	sudo gem install transmission-client
	
## Usage
Get a list of torrents and print its file names:

	require 'transmission-client'
	t = Transmission::Client.new('192.168.0.2')
	t.torrents.each do |torrent|
		puts torrent.name
	end
	
RDoc is still to be written, at the meantime have a look at the code to find out which methods are supported.
