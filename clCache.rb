require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
require './ardbinfo.rb'
require 'colors'
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
			table.column :wo, :integer
			table.column :dest, :string  
			table.column :orig , :string
			table.column :leaving, :integer
			table.column :algorithm, :integer
		end
	end
end
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
		cid = r.about[/\d+/].to_i
		result = Results.new();
		result.cid = cid
		result.wo = -1
		result.dest = ""
		result.orig = ""
		result.leaving = -1
		result.algorithm = 0
    post = Posts.new();
    post.mode = 	-1
    post.cid = 		cid.to_i
    post.title = 	title
    post.content = content
    post.link = 	r.link
    post.city =    r.link.downcase[/[a-z]+\./].chop
    post.posted = 	r.dc_date
		debugger if post.cid==nil
		if(post.save==true)
		  if(result.save==true)
			  x+=1
			  puts "NEW! "+title[0..70]
		  end
	  else
	    #These posts were not saved. 
	    #puts post.cid.to_s.negative.underline.red+" #{post.title}"
    end
	end
end
puts x.to_s+ " posts added to database"
