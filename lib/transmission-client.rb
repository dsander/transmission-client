require 'net/http'
require 'singleton'
require 'json'
require 'rubygems'
$:.unshift(File.dirname(__FILE__)) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'transmission-client/client'

if defined? EM
  begin
    require 'em-http'
    require 'transmission-client/em-connection'
  rescue LoadError
    require 'transmission-client/connection'
  end
else
  require 'transmission-client/connection'
end
require 'transmission-client/torrent'
require 'transmission-client/session'

