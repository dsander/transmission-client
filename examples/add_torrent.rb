require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'transmission-client'

magnet_href = "magnet:?xt=urn:btih:228f94bb71013ced94549ff032bce1600e25537d&dn=Prometheus+2012+DVDRip+XViD+AC3-REFiLL&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80&tr=udp%3A%2F%2Ftracker.publicbt.com%3A80&tr=udp%3A%2F%2Ftracker.istole.it%3A6969&tr=udp%3A%2F%2Ftracker.ccc.de%3A80"

EventMachine.run do
  t = Transmission::Client.new('127.0.0.1', 9091)
  t.add_torrent_by_file(magnet_href) do |response|
    puts "Added torrent"
    p response
    EventMachine.stop
  end
end
