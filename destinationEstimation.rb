require 'cgi'
require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
require 'json'
require 'colors'


ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	:database => "posts.sql"
)
class Posts < ActiveRecord::Base
	validates_uniqueness_of :cid
end
#37..49 
Posts.find_all_by_city(:santabarbara).each do |p|
	regex = /to +(\w+( +|\/)?)+/i
	p.title.gsub!(/ sb /i, " Santa Barbara ")
	p.title.gsub!(/ sd /i, " San Diego ")
	p.title.gsub!(/ sc /i, " Santa Cruz, CA ")
	p.title.gsub!(/ TMRW /i, " Tomorrow ")
	p.title.gsub!(/-+&gt;/, " to ")   
	title = p.title[0..60]
	print p.cid.to_s+"   "
	dest = title[regex]
	dest = dest[regex] if dest=~/ to /
	if(dest==nil)
		puts title[0..60].red
		next
	end
	if ARGV[0]
		debugger if p.cid==ARGV[0].to_i
	end
	stopwords  = Date::DAYNAMES + Date::ABBR_DAYNAMES
	stopwords += %w{ this early ASAP will Tomorrow today }
	#bound to cause problems later, as some cities contain these words
	#in them. Case in point, "Stockton"
	stopwords += %w{ on space }
	stopwords.each do |word|
		dest.gsub!(/#{word}.+/, "")
	end
	dest.gsub!("today","")
	dest.gsub!(/leaving.+/, "")
	dest.gsub!(/Tomorrow.+/i, "")
	dest.gsub!(/\d.+/,"")
	if dest=~/\//
		#Sometimes people are vauge. Rather than say where they are going, 
		#they say they are headed to a couple of places. Right now, this 
		#code pickes the first location. Soon, it will pick the most 
		#populated location
		dest = dest.split("/")[0]
	end
	if dest=~/ or /
		#Sometimes people are vuage. Rather than say a smaller city, they choice
		#to list two cities. Right now, this code picks the first location. Soon
		#it will pick the furthest from the origion craigslist
		dest = dest.split(" or ")[0]
	end
	puts title.gsub(dest,dest.green) unless dest==nil
	dest = dest.split[1..-1]

	url = "http://maps.googleapis.com/maps/api/geocode/json"
	url += "?sensor=false&address="
	url += CGI::escape dest.join(" ")
	res = Net::HTTP.get(URI.parse(url))
	sleep(0.1)
	puts (" "*14) + "ZERO_RESULTS".black if res=~/ZERO_RESULTS/
	next if res=~/ZERO_RESULTS/
	json = JSON::Parser.new res
	json  = json.parse
	puts json if json["results"][0]["geometry"]["location"]==nil
	latlng = json["results"][0]["geometry"]["location"]
	puts " "*19 +latlng.values.reverse.join(",  ")
end

