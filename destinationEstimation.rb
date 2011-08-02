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
	regex = /to (\w+( +|\/)?)+/i
	title = p.title 
	dest = title[regex]
	puts title.gsub(dest,dest.green) unless dest==nil
	puts title.red if dest==nil
end

#http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=place
