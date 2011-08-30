=begin
This program makes a little transit map of a route. 

It works by asking google directions api for a route from org, to dest. 
Google returns an object, from which I pull out the polylines.
The polylines are decoded into an array of lat lng coordinates.
The coordinates are then passed to the Yahoo geocoder.
Yahoo returns the name of the city at each coordinate.
Now we have a list of all the cities on the route.
The list of cities is iterated. 
Each city name is passed back to yahoo to acquire the coordinates of the city.
The coordinates are passed to the Pushpin API to acquire population data.
Small towns and CDP are removed from the list. 
The list of cities is then shroud in html and written to list.html
=end

require 'net/http'
require 'cgi'
require 'rubygems'
require 'json'
require 'ruby-debug'
require 'polyline_decode.rb'
require 'haversine.rb'

org = ARGV[0] ||"Burbank" 
dest = ARGV[1] ||"Santa Rosa"
url = "http://maps.googleapis.com/maps/api/directions/json?origin="
url += CGI::escape(org) 
url += "&sensor=true&destination="
url += CGI::escape(dest)
res = Net::HTTP.get(URI.parse(url))
json = JSON::Parser.new res
json  = json.parse
routes_a = json["routes"][0]["legs"][0]["steps"].collect do  |l|
	 l["polyline"]["points"] 
end
points = routes_a.collect do |l| 
	PolylineDecoder::decode(l)
end
Geocoder = :yahoo #:geonames
lastP = points[-1][-1]
names = []
points.each do |point|
	point.each do |p|
		haversine_distance(lastP[0],lastP[1],p[0],p[1])
		next if @distances["mi"]<1
		if Geocoder==:geonames
			url = "http://api.geonames.org/findNearbyPlaceNameJSON?lat="
			url += "#{p[0].to_s}&lng=#{p[1].to_s}&username=demo"
			res = Net::HTTP.get(URI.parse(url))
			json = JSON::Parser.new res
			json  = json.parse
			debugger
			if(json["status"]["value"]==18)
				puts "Geohost geocoding limit reached"
				puts "Try again tomarrow, or sign up for an acount"
				puts "http://geonames.org/"
			end
			name = json["geonames"][0]["name"]
			sleep(1)
		end
		if Geocoder==:yahoo
			unless(File.exists?("yAppId"))
				print "If you don't have a Yahoo Application ID, "
				print "please aquire one at http://bit.ly/nd8HpK "
				exit
			end
			appid = File.open("yAppId").read.chomp
			url = "http://where.yahooapis.com/geocode?"
			url += "gflags=R&flags=J&appid=#{appid}&q=#{p.join(",")}"
			res = Net::HTTP.get(URI.parse(url))
         json = JSON::Parser.new res
         json  = json.parse
			name = json["ResultSet"]["Results"][0]["city"]
		end
		names << name
		puts "#{p.join(", ")}       #{name}"
	end
end
names.uniq!
tp = JSON::Parser.new(File.open("tPoints.json").read).parse
stops = names.collect do |name|
	appid = File.open("yAppId").read.chomp
	url = "http://where.yahooapis.com/geocode?flags=J&q="
	url += CGI::escape(name) 
	url += "&appid=#{appid}"
	res = Net::HTTP.get(URI.parse(url))
	json = JSON::Parser.new res
	json  = json.parse
	chord =  json["ResultSet"]["Results"][0]
	chord = [chord["latitude"], chord["longitude"]]
	key = "A8C2B4DB310FF6A1987E1C06FCE83516"
	url = "http://place.pushpin.com/boundary/js?act=ctg&x="
	url += "#{chord[1].to_s}&y=#{chord[0]}&pti=16&fmt=json&"
	url += "attr=label,id,pop&key=#{key}"
	res = Net::HTTP.get(URI.parse(url))
   json = JSON::Parser.new res
   json  = json.parse
	next if json.empty?
	next if json[0]["pop"]<0
	label = json[0]["label"]
	print " T  " if tp.index label
	tPoint = tp.index(label) ? true : false
	print "    " unless tp.index label
	print label
	print " "*(40-label.length) 
	placeName = json[0]["label"][/\(.+\)/][1..-2] if json[0]["name"]=~/\(/
	placeName = json[0]["label"] unless json[0]["name"]=~/\(/
	print "#{json[0]["pop"].to_s.gsub(/(\d)(?=\d{3}+(\.\d*)?$)/, '\1,')}\n"
	{ :tPoint=>tPoint, :name=>placeName, :pop => json[0]["pop"] }
end
stops.compact!.uniq!
pp stops.map{ |l| l[:name]}.join("|")
fp = File.open("list.html", "w")
fp.write "<html><title>#{org} to #{dest}</title><body>\n"
fp.write %q{<link rel="stylesheet" type="text/css" href="list.css" />}
fp.write '<div class="terminus">'
stops.each do |stop|
  fp.write '<div class="transfer station">' if stop[:tPoint] #tPoint]
  fp.write '<div class="station">' unless stop[:tPoint]
  fp.write "<span>#{stop[:name]}</span>"
	#fp.write "<small>#{stop[:pop]}</small>"
  fp.write "</div>\n"
  end
fp.write "</div></body></html>\n"

