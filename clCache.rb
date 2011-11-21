require 'net/http'
require 'rubygems'
require 'active_record'
#require 'ruby-debug'
require 'hpricot'
require './ardbinfo.rb'
include Database

unless(File.exists?("posts.sql")) 
	ActiveRecord::Schema.define do
		create_table(:posts, :id=>false) do |table|
			table.column :cid,      :integer
			table.column :title,    :string	
			table.column :content , :string
			table.column :city,     :string
			table.column :link ,    :string
			table.column :posted,   :integer      
		end
		add_index(:posts,:cid, :unique => true)
		create_table(:results, :id=>false) do |table|
			table.column :cid,      :integer
			table.column :wo,       :integer
			table.column :fitness,  :integer 
			table.column :dest,     :string  
			table.column :orig,     :string
			table.column :leaving,  :integer
		end
	end
end
x=0
cities = [:losangeles, :santabarbara, :santamaria, :slo, 
          :monterey, :sfbay, :portland, :seattle]
posts = cities.map do |city|
	print city.to_s.upcase
	feed = "http://#{city.to_s}.craigslist.org/rid/index.rss"
	rss = Hpricot.parse(Net::HTTP.get(URI.parse(feed)))
	print "."
	redo if rss == nil
	posts = (rss/:item).collect do |r|
	  cid = (r/"dc:source").text[/\d+/].to_i
		next if(!Posts.find_all_by_cid(cid).empty?)
		title = (r/:title).text.gsub(">"," to ")
		content = (r/:description).text.gsub("<br.{0,3}>", "\n")
		content = content[0..content.index("<!-- START")-1]
		#.gsub(%r{</?[^>]+?>}, '') #This should strip html
		#content = content.tr(",",".").tr("\n","   ")[0..-5]
		content = Hpricot::parse(content).inner_text
    post = Posts.new();
    post.cid = 		cid.to_i
    post.title = 	title
    post.content = content
    post.link = 	(r/"dc:source").text
    post.city =    post.link.downcase[/[a-z]+\./].chop
    post.posted = 	Time.parse((r/:dc_date).text).to_i
    post
  end
  puts "."
  posts
end

posts.flatten.compact.each do |post|
  if(post.save==true)
    result = Results.new({
      :wo       => -1,
      :fitness  => -1,
      :dest     => "",
      :orig     => "",
      :leaving  => -1
    })
    result.cid = post.cid
    if(result.save)
		  x+=1
		  #puts "NEW! "+post.title[0..70]
	  end
  else
    #These posts were not saved. 
    #puts post.cid.to_s.negative.underline.red+" #{post.title}"
  end
end

puts x.to_s+ " posts added to database"
