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
require "tactful_tokenizer"
require 'chronic'
require 'nickel'
include Database

class Fixnum
  def is_upper_case?
    self.chr=~/[A-Z]/ ? true  : false
  end
end
class String 
  def normalize
    self.downcase.scan(/([a-z]| )/).join
  end
end
if ARGV[0].to_i>0
	posts = [Posts.find_by_cid(ARGV[0])]
else
  recent = Time.now.to_i - (60*60)
  if(ARGV[0]=='-a')
    posts = Posts.find(:all)
  else
    #results = Results.find_all_by_wo(1)
    #posts = Posts.find(:all, :conditions=> "cid in ("+results.map{|r|r.cid}.join(",")+")")
    #posts = posts.select{ |l| l.mode==1 }
    posts = Posts.find_all_by_city("sfbay", :conditions => 'posted > 1320217200 and posted < 1320303599')
  end
 #posts = Posts.all(:conditions => 'title  like "%no%ca%"')
	#posts = Posts.all(:conditions => 
	  #{:posted => (Time.now.to_i-(60*60*10))..Time.now.to_i, :city=> :santabarbara })
#   posts = Posts.find(:all)
end
nils = 0
posts.sort_by{ |p| p.posted }
posts = posts.select do |p|
  r = Results.find_by_cid p.cid
  r.wo==0
end
#posts = posts[0..100]
tact = TactfulTokenizer::Model.new
posts.each do |post|
  print post.cid.to_s.bold+"  "
  post.title.gsub!(/a\.m\./i,"am")
  post.title.gsub!(/p\.m\./i,"pm")
  post.content.gsub!(/a\.m\./i,"am")
  post.content.gsub!(/p\.m\./i,"pm")
  post.title.gsub!(/anytime/i,"")
  post.title.gsub!(/nth/,"th")
  post.content.gsub!(/nth/,"th")
  post.content.gsub!(/anytime/i,"")
  post.title.tr!("-","/")
  post.content.tr!("-","/")
  post.title.tr!("?",".")
  post.content.tr!("?",".")
  post.title.gsub!(/\Wthur(s)?(day)?\W/i," Thursday ")
  post.content.gsub!(/\Wthur(s)?(day)?\W/i," Thursday ")
  resp = Nickel.parse("foobar")
  sentences = [post.title ] +tact.tokenize_text(post.content)
  #debugger
  idx = 0
  while(resp.occurrences.empty? and idx<sentences.length)
    begin
      resp = Nickel.parse(sentences[idx], Time.at(post.posted))
    rescue NoMethodError, RuntimeError
      #ok...
    end
    idx+=1
  end
  if(!resp.occurrences.empty?)
    dt = Date.parse resp.occurrences[-1].start_date.date  
  else
    resp = nil
  end
=begin
  resp =  Nickel.parse(post.title, Time.at(post.posted))
  #debugger
  if(!resp.occurrences.empty?)
    dt = Date.parse resp.occurrences[-1].start_date.date  
  else
    resp = nil
  end
  if(resp==nil)
    c = post.content
    begin
      resp =  Nickel.parse(c, Time.at(post.posted))
      
    rescue NoMethodError, RuntimeError
      c = c.split[3..-3].join(" ")
      retry
    end
    if(resp.message.normalize!=post.content.normalize)
      if(!resp.occurrences.empty?)
        dt = Date.parse resp.occurrences[-1].start_date.date
      else
        idx = 0
        c = post.content        
        c = c.split(/\n+/)
        #Use tactfull tokanizer for this
        c = c.join.split(/\.+/i) if(c.length<2)
        while(resp.occurrences.empty? and idx<c.length)
          
          begin
            resp = Nickel.parse(c[idx], Time.at(post.posted))
          rescue RuntimeError, NoMethodError
            break if(c[idx].split[3..-3])==nil
            c[idx] = c[idx].split[3..-3].join(" ")
            retry
          end
          idx+=1 if(resp.occurrences.empty?)
        end
        if(resp.occurrences.empty?)
          dt = nil
        else
          dt = Date.parse resp.occurrences[-1].start_date.date
        end
      end
    end
  end
=end
  print dt.to_s
  nils+=1 unless dt
  print "\n"
end
#puts "Posts: #{posts.length}"
#puts "Fails: #{nils}"
print nils.to_s+" out of #{posts.length} posts couldn't be dated: "
failRate = ((100*nils)/posts.length.to_f)
printf("%2.2f%% failure rate",failRate)