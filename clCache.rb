require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
require './ardbinfo.rb'
include Database

def feed(city="santabarbara")
	"http://#{city.to_s}.craigslist.org/rid/index.rss"
end
unless(File.exists?("posts.sql")) 
	ActiveRecord::Schema.define do
		create_table(:posts, :id=>false) do |table|
			table.column :cid, :integer
			table.column :title, :string	
			table.column :content , :string
			table.column :city, :string
			table.column :link , :string
			table.column :posted, :integer
			table.column :mode, :integer
		end
		create_table(:results, :id=>false) do |table|
			table.column :cid, :integer
			table.column :dest, :string  
			table.column :orig , :string
			table.column :lat, :integer
			table.column :lng , :integer
			table.column :leaving, :integer
			table.column :algorithm, :integer
		end
	end
end

=begin
ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	#:dbfile  => ":memory:"
	:database => "posts.sql"
)

class Posts < ActiveRecord::Base
	validates_uniqueness_of :cid
	has_one(:result, {:foreign_key => :cid , :primary_key => :cid })
end
class Results < ActiveRecord::Base
	validates_uniqueness_of :cid
	belongs_to(:posts,{ :foreign_key => :cid, :primary_key => :cid})
end
=end
x=0
cities = [:losangeles, :santabarbara, :santamaria, :slo, :monterey, :sfbay, :portland, :seattle]
cities.each do |city|
	puts city.to_s.upcase
	rss = RSS::Parser.parse(Net::HTTP.get(URI.parse(feed(city))),true)
	redo if rss == nil
	posts = rss.items.collect do |r|
		title = r.title.gsub("-*&gt;"," to ")
		title = r.title.gsub(">"," to ")
		content = r.description
		content = r.description.gsub("<br.{0,3}>", "\n")
		content = r.description[0..r.description.index("<!-- START")-1]
		#.gsub(%r{</?[^>]+?>}, '') #This should strip html
		#content = content.tr(",",".").tr("\n","   ")[0..-5]
		content = Hpricot::parse(content).inner_text
		id = r.about[/\d+/]
		p = Posts.new({
			:cid => 		id,
			:title => 	title,
			:content => content,
			:link => 	r.link,
			:city =>    r.link.downcase[/[a-z]+\./].chop,
			:posted => 	r.dc_date,
			:mode => 	0
		}).save
		Results.new({
			:cid =>		id,
			:dest => 	"",
			:orig =>		"",
			:lat	=>		-1,
			:lng	=>		-1,
			:leaving =>	-1,
			:algorithm =>0
		}).save
		if p
			x+=1
			puts "NEW! "+title[0..70]
		end
	end
end
puts x.to_s+ " posts added to database"
