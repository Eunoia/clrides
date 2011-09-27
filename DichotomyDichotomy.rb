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

#this would work by loading all rows 
#this would work by loading the row, if there isn't data in a collom, divine it.
cgi = cgi.new
params = cgi.params
cid = params['cid'].to_i
	#	debugger if p.cid==ARGV[0].to_i
	posts = [Posts.find_by_cid(ARGV[0])]
else
	#posts = Posts.all(:conditions => {:posted => (Time.now.to_i-(60*60*10))..Time.now.to_i, :city=> :santabarbara })
	posts = Posts.find_all_by_city(:santabarbara)
end
posts.each do |p|
print p.cid.to_s.bold
print "\t"+p.title[0..60].dark.underline.dark+"\n"
s = 0
offset = 69
l = p.content.length
fc = []
e= 0
while(e<l) 
	e = s+offset
	fc << p.content[s..e]
	s = e+1
end
fc.each do |f|
#printf("\t%s\n", f.tr("\n\t",""))
end
end

