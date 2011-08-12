require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'

feed= "http://santabarbara.craigslist.org/rid/index.rss"
rss = RSS::Parser.parse(Net::HTTP.get(URI.parse(feed)),true)


ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	#:dbfile  => ":memory:"
	:database => "posts.sql"
)

unless(File.exists?("posts.sql")) 
		  ActiveRecord::Schema.define do
					 create_table(:posts, :id=>false) do |table|
								table.column :cid, :integer
								table.column :title, :string	
								table.column :content , :string
								table.column :link , :string
								table.column :posted, :integer
								table.column :mode, :integer
					 end
		  end
end

class Posts < ActiveRecord::Base
	validates_uniqueness_of :cid
end
x=0
posts = rss.items.collect do |r|
	title = r.title.gsub("-+>&gt;"," to ")
	content = r.description.gsub("<br>", "\n")
	content = content[/^.+/]
		  #.gsub(%r{</?[^>]+?>}, '') #This should strip html
	content = content.tr(",",".").tr("\n","   ")[0..-5]
	id = r.about[/\d+/]
	p = Posts.new({
		:cid => 		id,
		:title => 	title,
		:content => content,
		:link => 	r.link,
		:posted => 	r.dc_date,
		:mode => 	0
	}).save
	if p
		x+=1
		puts "NEW! "+title[0..70]
	end
end
puts x.to_s+ " posts added to database"
