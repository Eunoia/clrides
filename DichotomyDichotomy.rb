#When run this program will select all the rows in results that do not do not
#contain a value for wo. 

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
require 'classifier'
require 'colors'
require './ardbinfo.rb'
include Database

malWords =  %w{ pool limo calander Ridejoy BayShuttle dui  casino } 
malWords += %w{ commute taxi rentals  designated commuting Errand }
malWords += %w{ relayrides flat| Shawn| MESSENGER| Errand| Errand }
malWords += %w{ driver| pool| mckenna M-F| Mon-Fri tingly }

places = YAML::load File.open("cities.yaml").read
places = places.select{ |l| l=~/ / }.map{ |l| l.split }.flatten.uniq
places += Date::ABBR_DAYNAMES+Date::ABBR_MONTHNAMES+Date::MONTHNAMES+Date::DAYNAMES
places += ['tues']
places += ['seattle', 'kitsap', 'pdx', 'sf', 'boise', 'cali', 'santa', 'cruz']
places += ['montana', 'sea', 'buffalo', 'kansas', 'la', 'missoula', 'barbara'] 
places += ['oregon', 'point', 'reyes', 'bellingham', 'south', 'ashland',  'n']
places += ['tahoe', 'bart', 'seattlebellingham', 'north', 'lake', 'vancouver']
places += ['tacoma', 'osos', 'san', 'luis', 'obispo', 'paso', 'morro', 'bay' ]
places += [ 'wa', 'sb','osos', 'slo','los', 'clearlake','ca', 'grants','pass']
places += ['sequim', 'seatac', 'sfo', 'rosa', 'spokane', 'tri', 'five', 'or' ]
places += ['city','cities','station', 'area', 'oly', 'california', 'northern']
places += ['bolder', 'co',  'michigan', 'st','oc','louis','airport', 'county'] 
places += [ 'oc', 'rd','sc', 'francisco','diego','thousand','renton', 'falls']
places += ['boulder', 'mo', 'grand', 'rapids', 'pa',  'girlfriend', 'valley' ]
places += ['ashbury',  'colorado', 'bainbridge', 'island', 'idaho', 'angeles']
places += ['utah', 'th', 'sd', 'kennewick','reno','ukiha','reno', 'wisconsin']
places += ['anacortes', 'yosemite',  'anacortes', 'socal', 'houston', 'texas']
places += ['walla', 'menlo', 'park', 'jose','silverdale', 'midwest', 'socal' ]
places += ['norcal','cal','sfsu','montrose', 'berkeley','eugene', 'corvallis']
places += ['pahrump','mendocino']
places.compact!.map!{ |p| p.downcase }
@@places = places
class String
 # CORPUS_SKIP_WORDS+= @@places
end
train3 = File.open("train3.csv").read.split("\n").collect do |t| 
   text1 = t.split(",")[1]+"  "
   if(text1=~/\)/)
	   l = text1.index("(")
	   r = text1.index(")")
	   text = text1[0..l-1]+text1[r+1..-1]
   else 
     text = text1
   end
   text += t.split(",")[2]
   text.tr!("//.-@(--)!!?\',"," ")
   text = text.downcase.scan(/[a-z\d{,3} ]/).to_s.split-places
   text = text.join(" ")
  { 
    :classification => t.split(",")[0].downcase.to_sym,
    :text =>  text
  }
end
train3 = train3.reject{ |t| t[:classification]==:other  } 
train3 = train3.sort_by{ rand }
b = Classifier::Bayes.new :wanted, :offered
train3.each { |datum| b.train(datum[:classification],datum[:text]) }

if ARGV[0]
	results = [Results.find_by_cid(ARGV[0].to_sym)]
else
	results = Results.find(:all, :conditions => { :wo => -1 })
end
errors = [] 
results.each do |result|
  post = Posts.find_all_by_cid(result.cid)[0]
  errors << result.cid  if post==nil
  next if post==nil
  #mode is the fitness of a post: 1 fit, 0 unfit
  malWords.each do |mal|
    if(mal[-1..-1]=="|")
      post.mode = 0 if post.title=~/#{mal[0..-2]}/i
    else
      post.mode = 0 if post.content=~/#{mal}/i
    end
  end
  post.mode = 1 if post.mode==-1
  text = post.title
  if(text=~/\)/ and text=~/\(/)
	 l = text.index("(")
	 r = text.index(")")
	 debugger if(l.class==NilClass)
	 text = text[0..l-1]+text[r+1..-1]
  else 
   text = text
  end
  text += "\t"+post.content
  text.tr!("//.-@(--)!!?\',"," ")
  text = text.downcase.scan(/[a-z\d{,3} ]/).to_s.split-places
  text = text.join(" ")
  resp = b.classify(text)
  if(post.mode==1)
    puts resp.bold.green+"\t\t"+post.title[0..60]
  else
    puts resp.bold.yellow+"\t\t"+post.title[0..60]
  end
  wo = resp.to_s.downcase.intern==:offered ? 1 : 0
  result.wo = wo
  result.algorithm = 0
	result.save
	post.save
end
time = Time.now.to_i - start
m = (time/60).to_i
s = time%60
print results.length.to_s+" posts classified in #{m}:#{s} minutes \n"
