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
			  create_table :posts do |table|
				  table.column :title, :string	
				  table.column :content , :string
				  table.column :link , :string
				  table.column :posted, :integer
			  end
		  end
end

class Posts < ActiveRecord::Base
end
class ::DateTime

alias_method :to_s, :to_formatted_s

end
posts = rss.items.collect do |r|
	title = r.title.gsub("-->&gt;"," to ")
	content = r.description.gsub("<br>", "\n")
	content = content[/^.+/]
		  #.gsub(%r{</?[^>]+?>}, '') #This should strip html
	content = content.tr(",",".").tr("\n","   ")[0..-5]
	Posts.new({
		:id => r.about[/\d+/],
		:title => title,
		:content => content,
		:link => r.link,
		:posted => r.dc_date
	}).save
end
