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
if ARGV[0]
	#	debugger if p.cid==ARGV[0].to_i
	posts = [Posts.find_by_cid(ARGV[0])]
else
	#posts = Posts.all(:conditions => {:posted => (Time.now.to_i-(60*60*10))..Time.now.to_i, :city=> :santabarbara })
	posts = Posts.find_all_by_city(:santabarbara)
end
posts.each do |p|
	regex = /to +(\w+( +|\/)?)+/i
	#It might be a good idea to also change "2" to to; however it could 
	#break chronemics, so maybe latter.
	p.title.gsub!(/-*&gt;/, " to ")   
	p.title.gsub!(/ sb /i, " Santa Barbara ")
	#Google thinks that lodi italy is more relevent
	p.title.gsub!(/ lodi /i, " Lodi California")
	p.title.gsub!(/ ebay /i, " East Bay ")
	p.title.gsub!(/ sd /i, " San Diego ")
	p.title.gsub!(/ sj /i, " San Jose ")
	#Fun fact: Google returns the choords of sac airport, but can't
	#return the chordinates of the the city of sacremento
	p.title.gsub!(/ sacramento /i, " sac ")
	p.title.gsub!(/ iv /i, " Isla Vista ")
	p.title.gsub!(/ l.?a.? /i, " Los angeles ")
	#This whole sections needs to take into account 
	#that people uses slashes. 
	p.title.gsub!(/ o.?c.?( |\/)/i, " Anaheim/Irvine ")
	p.title.gsub!(/ sc /i, " Santa Cruz, CA ")
	p.title.gsub!(/ TMRW /i, " Tomorrow ")
	p.title.gsub!(/ brc /i, " burning man ")
	p.title.gsub!(/ the playa /i, " burning man ")
	#At times, people can be creative in their use of pp heads
	p.title.gsub!(/-/, " to ") unless p.title=~/ to /
	p.title.gsub!(/:/, " to ") unless p.title=~/ to /
	title = p.title#[0..60]
	print p.cid.to_s+"   "
	dest = title[regex]
	if(dest==nil)
		puts title[0..60].red
		next
	end
	while(dest[2..-1]=~/to /)
			  dest = dest[3..-1][regex] #if dest[2..-1]=~/to /
	end
	
	stopwords  = Date::DAYNAMES + Date::ABBR_DAYNAMES
	stopwords += (0..9).to_a.map{ |n| n.to_s }
	stopwords[stopwords.index("Mon")]="Mon "
	stopwords += %w{ this early tonight ASAP will tomorrow today }
	#bound to cause problems later, as some cities contain these words
	#in them. Case in point, "StocktON", "PlesentON", and "Santa MONica"
	stopwords += [ " on", "space", "Early", "late" ]
	#From is a special word, as it is the head of a prepositional phrase
	stopwords += %w{ from }
	#Holidays 
	stopwords += %w{ labor }
	stopwords += %w{ sept aug sep }
	stopwords.each do |word|
		#debugger if word=~/on/i
		dest.gsub!(/#{word}(\W|\z).*/i, "  ")
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

	dest = dest.split[1..-1].join(" ")
	puts title.sub(dest,dest.green)[0..70] unless dest==nil
	url = "http://maps.googleapis.com/maps/api/geocode/json"
	#url += "?sensor=false&region=com&address="
	url += "?sensor=false&bounds=51,-69|33,-129&address="
	url += CGI::escape dest#.join(" ")
	puts url
	#url.gsub!(",","%2C")
	res = Net::HTTP.get(URI.parse(URI::encode(url)))
	sleep(0.8)
	puts (" "*14) + "ZERO_RESULTS".black if res=~/ZERO_RESULTS/
	next if res=~/ZERO_RESULTS/
	json = JSON::Parser.new res
	json  = json.parse
	puts json if json["results"][0]["geometry"]["location"]==nil
	latlng = json["results"][0]["geometry"]["location"]
	puts " "*19 +latlng.values.reverse.join(",  ")
end

