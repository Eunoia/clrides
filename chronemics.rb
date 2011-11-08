#This program determins leaving time from a post.

start = Time.now.to_i
require 'cgi'
require 'rss'
require 'net/http'
require 'rubygems'
require 'hpricot'
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
#require 'json'
require 'colors'
require './ardbinfo.rb'
require 'chronic'
include Database


if ARGV[0].to_i>0
	posts = [Posts.find_by_cid(ARGV[0])]
else
  recent = Time.now.to_i - (60*60)
  if(ARGV[0]=='-a')
    posts = Posts.find(:all)
  else
    posts = Posts.all(:conditions => "posted > #{Time.now.to_i - (60*60*4)} ")
  end
 #posts = Posts.all(:conditions => 'title  like "%no%ca%"')
	#posts = Posts.all(:conditions => 
	  #{:posted => (Time.now.to_i-(60*60*10))..Time.now.to_i, :city=> :santabarbara })
#   posts = Posts.find(:all)
end

posts.sort_by{ |p| p.posted }
posts[0..100].each do |post|
  resp =  Chronic.parse(post.title, :now => Time.at(post.posted))
  if(resp==nil)
    resp = Chronic.parse(post.content, :now => Time.at(post.posted))
  end
  print post.cid.to_s.bold+"  "
  print resp.to_s
  print "\n"
end