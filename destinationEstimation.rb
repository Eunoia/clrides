require 'cgi'
require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
require 'json'

class String

    def red; colorize(self, "\e[1m\e[31m"); end
    def green; colorize(self, "\e[1m\e[32m"); end
    def dark_green; colorize(self, "\e[32m"); end
    def yellow; colorize(self, "\e[1m\e[33m"); end
    def blue; colorize(self, "\e[1m\e[34m"); end
    def dark_blue; colorize(self, "\e[34m"); end
    def pur; colorize(self, "\e[1m\e[35m"); end
    def black; colorize(self, "\e[1m\e[30m"); end
    def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end


ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	:database => "posts.sql"
)
class Posts < ActiveRecord::Base
	validates_uniqueness_of :cid
end
Posts.find(:all).each do |p|
	if ARGV[0]
		debugger if p.cid==ARGV[0].to_i
	end
	regex = /to (\w+( +|\/)?)+/i
	title = p.title[0..60]
	print p.cid.to_s+"   "
	dest = title[regex]
	if(dest==nil)
		puts title[0..60].red
		next
	end
	stopwards  = Date::DAYNAMES + Date::ABBR_DAYNAMES
	stopwards.each do |word|
		dest.gsub!(word, "")
	end
	dest.gsub!("today","")
	dest.gsub!(/leaving.+/, "")
	dest.gsub!(/\d.+/,"")
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
	puts " "*14 +latlng.to_a.join("  ")
end

