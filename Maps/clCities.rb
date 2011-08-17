#This is a list of all the cities(hubs) served by Craigslist
#
#
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'cgi'
require 'json'

url = 'http://geo.craigslist.org/iso/us/ca'

doc = Hpricot::parse(Net::HTTP.get(URI.parse(url)))
(doc/("#list")/:a).each do |l|
	url = "http://maps.googleapis.com/maps/api/geocode/json"
	url += "?sensor=false&address="
	url += CGI::escape(l.inner_text)
	json =  JSON::Parser.new(Net::HTTP.get(URI.parse(url))).parse
	latlng = json["results"][0]["geometry"]["location"]
	puts l.inner_text
	puts " "*14 +latlng.to_a.reverse.join("  ")
	sleep 0.1
end

