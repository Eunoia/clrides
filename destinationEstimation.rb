require 'cgi'
require 'rss'
require 'net/http'
require 'rubygems'
#require 'hpricot'
#require "tactful_tokenizer"
require 'active_record'
require 'ruby-debug'
require 'sqlite3'
#require 'json'
require 'colors'

#This file should be called LocusPocus, he he he
ActiveRecord::Base.establish_connection(
	:adapter => "sqlite3",
	:database => "posts.sql"
)
class Posts < ActiveRecord::Base
  # validates_uniqueness_of :cid
  set_primary_key :cid
  # has_one(:result, {:foreign_key => :cid , :primary_key => :cid })
end
class Results < ActiveRecord::Base
 #  validates_uniqueness_of :cid
 set_primary_key :cid
 
 #  belongs_to(:posts,{ :foreign_key => :cid, :primary_key => :cid})
end
#ActiveRecord::Base.logger = Logger.new("/destinationEstimation.log")
class Fixnum
  def is_upper_case?
    self.chr=~/[A-Z]/ ? true  : false
  end
end
class Array
def shuffle
self.sort_by{ rand }
end
end
class String
  def bag
    self.tr(",()-/"," ").scan(/([a-z]| )/i).join.downcase.split
  end
  def deprive(str="(") 
    self.gsub(%r{</?[^>]+?>},"") if(str=="<")
    self.gsub(%r{\(/?[^\)]+?[^(\) ?$)]\)},"") if(str=="(")
  end
end
def cityScore(place,title="")
  return -1 if place==nil
  place = (@cities&place.deprive.bag)#.sort_by{ |l| title[@regex_d].downcase.index(l) }  
	place.length
end
def further(o,*p)
  #This function returns which point in array p is furtist from point o
end

if ARGV[0]
	posts = [Posts.find_by_cid(ARGV[0])]
else
  recent = Time.now - (60*60) 
  posts = Posts.all(:conditions => "posted > #{recent} ")
 #posts = Posts.all(:conditions => 'title  like "%no%ca%"')
	#posts = Posts.all(:conditions => 
	  #{:posted => (Time.now.to_i-(60*60*10))..Time.now.to_i, :city=> :santabarbara })
#   posts = Posts.find(:all)
end

dests = []
origs = []
#cities should be split into a neighborhood array to hold location specific
#items. e.g no for portland, inner for sfbay
cardinals = %w{ north east south west n e s w }
cities = YAML::load(File.open("cities.yaml").read).map{ |c| c.split }.flatten
cities += %w{ sf seattle spokane salt lake city nor socal denver Vegas }
cities += %w{ bellingham Tacoma Vancouver  Yakima vancouver Boise moab }
cities += %w{ tuson Pullman  Walla Ritzville Ellensburg  phoenix Ukiha } 
cities += %w{ Arcada  Isla Vista SLO SM Bay lax  sylmar Eugene EastBay } 
cities += %w{ sonoma excelsior dc Ohio Albuquerque NorCal Northern cal } 
cities += %w{ sylmar cali BC San luis  obispo Irvaheim Missoula  inner }
cities += %w{ oakley  Sur Federal UCSD Obipso WA Everett ashbury  UCSB }
cities += %w{ ILLINOIS Dakota no doylestown Mexico TriCities  townsend }
cities += %w{ no coast England govt couer dalene Bozeman AZ sebastapol }
cities += %w{ Florida Korea BRC  Kokomo  Texas Michigan WSU SFO jersey }
cities += %w{ Anacortes  Edmonds Breittenbush  UCLA Minneapolis Alaska }
cities += %w{ TUNICA poly MISSISSIPPI nob Issaquah Port Calgary Trukee }
cities += %w{ Kansas Philadelphia Hathorne  greenlake Southeast inland }
cities += %w{ Pearl Idaho Klamath dix nj goose mt SW SE NW NE treasure }
cities += %w{ Mercer Whidbey Toluca Feliz SLC fife Anne Polsen Fraizer }
cities += %w{ WY Panhandle Cucamungo quarter flags CA center montclair }
cities += %w{ Diridon Caltrain Wall SugarPine Fishermans USC Snohomish }
cities += %w{ FL Colombia StJohns StLouis Syndey  Houston  Yellowstone }
cities += %w{ Davidson  Pittsburgh PROVO Pensacola Polson  MA Columbus }
cities += %w{ Laytoville MA Shoreline Tukwila Nampa  Wenatchee Midwest }
cities += %w{ CSULA Telluride Eastern UCSC SFV NC KC wyoming Louisiana }
cities += %w{ Charboneau  Navodo  anchorage UCSC  atlantic Yellowstone }
cities += %w{ Toppenish UCSC Durango lacey cabo Tonasket Spanaway elum }
cities += %w{ Kelowna Tucson FLAGSTAFF SEDONA  financial fair hangtown }
cities += %w{ union UCD Eastside Carolina medford Esalen Reno Red Hawk }
cities += %w{ cle station Breitenbush Downtown  Seatac}
#The pnw devides towns into quarters. My regexp can't hack it, so maybe latter
#cities += %w{  } 
fp = File.open("locals.csv","w")
cities.collect{ |c| c.downcase! }
notCities =  %w{ lewis on sun and home of i  need center points }
notCities += %w{ the at medical show you cow by deep see m noon }
notCities += %w{ play warm riders two one last a gas may berlin }
notCities += %w{ scenic wonder  k sisters friend end round time } 
notCities += %w{ trailer travel  dew village r  ready d out day }
notCities += %w{ albina Alviso giant bull American  Avenue date }
notCities += %w{ fair dog  way  manor  blink  old place   sugar }
notCities += %w{ bucks station love bunch  vacation  affordable }
notCities += %w{ joes nice }
notCities.each { |notCity| cities.delete(notCity) }
@cities = cities
malWords =  %w{ pool limo calander Ridejoy BayShuttle dui  casino } 
malWords += %w{ commute taxi rentals designated commuting }
malWords += %w{ relayrides flat| Shawn| MESSENGER| Errand| Errand }
malWords += %w{ driver| pool| mckenna M-F| Mon-Fri tingly }
malWords.each do |mal|
  posts.reject! do |post|  
    if(mal[-1..-1]=="|")
      post.title=~/#{mal[0..-2]}/i
    else
      post.content=~/#{mal}/i
    end
  end
end
atEnd = []
redoLevel = 0;
regex_d = /\Wto(o)?(ward(s)?)? +(\w+( +|\/|\.)?)+/i
regex_o = /\Wfrom +(\w+( +|\/)?)+/i
@regex_d = regex_d

posts.each do |p|	
  print p.cid.to_s+"   "
	p.title = (" "+p.title+" ")
	p.title.gsub!(".."," ") 
	p.title.gsub!("*"," ")
	p.title.tr!("=?"," ")
	p.title.tr!("~\t"," ")
	p.title.gsub!("!"," ! ")
	p.title.gsub!(","," , ")
	p.title.gsub!(/ to(o)?\W*from /i," to ")
	p.title.gsub!(/-*(&gt;)+/, " to ")
	p.title.gsub!("&amp;"," and ")
	p.title.gsub!("&", " and ")
	#This is where code to handle the use of - goes
	#At times, people can be creative in their use of pp heads
  if(p.title.strip[-4..-1]=~/\)/)
    finalParens = p.title.strip.reverse[/^\) ?.+? ?\(/]
    if(finalParens!=nil)
      if(finalParens.reverse[1..-2]=~/-/)
  	    #p.title.gsub!("-"," to ")
  	    p.title[p.title.scan(/\(.+-.+\)/)[0]]=p.title.scan(/\(.+-.+\)/)[0].gsub("-"," to ")
      end
    end
  end
  unless (p.title.deprive=~/ to /i)
    if p.title=~/-/i
      p.title.gsub!(/:/, " from ")
    else
      p.title.gsub!(/:/i, " to ")
    end
    p.title.gsub!("-"," to ") #unless p.title=~/ to /i
  end
	
  p.title.gsub!(" 2 ", " to ")
  p.title.gsub!(":"," ")
  p.title.gsub!(/ too /i," to ")
  p.title.gsub!("!", " ")
  p.title.tr!(".","")
#	p.title.gsub!(/:/, " to ") unless p.title=~/ to /i
#	p.title.gsub!(/-/, " to ") unless p.title=~/ to /i
#	p.title.gsub!(/-/," - ")
  p.title.gsub!("("," ( ");
  p.title.gsub!(")"," ) ");
  p.title.gsub!(/-/," ")
	while(p.title=~/[a-z] ?\/ ?[ a-z]/i)
	  slashMark = p.title.index(/[a-z] ?\/ ?[ a-z]/i) 
	  slashMark += p.title[slashMark..slashMark+3].index("/")-1
  	p.title[slashMark+1] = " or "
	end
	p.title.tr!("\'","")
	#people be round trippin, breaking my nlp
	p.title.gsub!(/ to and from /i," to ")
	p.title = " to "+p.title unless p.title=~/ to /i
	#Google thinks that lodi italy is more relevent
	p.title.gsub!(/ lodi /i, " Lodi California ")
#	p.title.gsub!(/ south bay /i, " San Jose ") #Confusion with la
	p.title.gsub!(/ San F(r)?an /i, " San Francisco ")
	p.title.gsub!(/ ebay /i, " East Bay ")
	p.title.gsub!(/ diego /i, " San Diego ")
	p.title.gsub!(/ BOI /i, " Boise ")
	p.title.gsub!(/ san san /i, " San ")
	p.title.gsub!(/ (half)? ?(the)?mo+n ?(bay)? /i, " Half Moon Bay ")
	p.title.gsub!(/ san ?d(i|e)?(e|i)?go /i, " San Diego ")
	p.title.gsub!(/ Por(t)?(l)*and/i, " portland ")
	p.title.gsub!(/ sd /i, " San Diego ")
	p.title.gsub!(/ p(or)?tl(an)?d /i, " pdx ")
	p.title.gsub!(/ taho(e)? /i, " Tahoe ")
	p.title.gsub!(/ santa Bar(a)?b(a)?ra /i, " Santa Barbara ")
	p.title.gsub!(/ sb /i, " Santa Barbara ")
	p.title.gsub!(/ sj /i, " San Jose ")
	if(p.title=~/SFO/)
	  p.title.gsub!(/ SFO /," SF ") unless p.content=~/air?port/i
  end
  
	p.title.gsub!(/ sanfran /i, " San Francisco ")
  #This line turns all the permutations of So Cal into one word
  p.title.gsub!(/ so(\w|\.)* *ca\w+ /i, " socal ")
  #This still cannot differentiate between NorCal and North Carolina
  #p.title.gsub!(/ n(o)?(r)?\w*(-| )*ca([^r]| )?\w* /i," norCal ")
  p.title.gsub!(/ n(o)?(r)?\w*(-| )*ca([^r]| )+ /i," norCal ")
  p.title.gsub!(/ ny(c)? /i," New York ")
  
	#Fun fact: Google returns the choords of sac airport, but can't
	#return the chordinates of the the city of sacremento
	p.title.gsub!(/ sac(\w+)? /i, " sacramento ")
	p.title.gsub!(/ i\.?v\.?\W/i, " Isla Vista ")
	p.title.gsub!(/ l\.?a\.? /i, " Los angeles ")
	p.title.gsub!(/ ABQ /i, " Albuquerque ")
  p.title.gsub!(/ los ?A(n|m)\w+s /i, " Los angeles ")
  p.title.gsub!(/ l ? a? /i, " Los angeles ")
  p.title.gsub!(/ b(e)?(v)? hills/i, " Beverly Hills ")
	p.title.gsub!(/ W\.? *Hills /i," Woodland hills ")	
	p.title.gsub!(/ s\.?f\.? /i, " SF ")
	p.title.gsub!(/ sfbay /i, " sf bay area ")
	p.title.gsub!(/ Frisco /i, " SF ")
	p.title.gsub!(/ Re(a)?dding /i, " Redding ")	
	p.title.gsub!(/ Los Ang+ /i, " Los angeles ")
	p.title.gsub!(/ Tu(s|c)?(s|c)?on /i, " Tucson ")
	p.title.gsub!(/ Mich /i, " Michigan ")
	p.title.gsub!(/ nc /i, " North carolina ")
	p.title.gsub!(/ Orang(e) /i," orange ")
  
	p.title.gsub!(/ o( |\.)?c( |\.)?( |\/)/i, " Irvaheim ")
	p.title.gsub!(/ sd /i, " San Diego ")
	p.title.gsub!(/ sm /i, " Santa Maria ")
	p.title.gsub!(/ sugar pine /i, " SugarPine ")
	p.title.gsub!(/ osos /i, " los osos ")
	p.title.gsub!(/ Obi(s|p|b)(s|p|b)o /i," Obispo " )
	p.title.gsub!(/ bak(e|o)\w* /i, " Bakersfield ")
	p.title.gsub!(/ down ?town /i, " Downtown ")
	p.title.gsub!(/ Arca(d|t)a /i, " Arcata ")
	p.title.gsub!(/ K\w* Falls /i, " Klamath Falls ")
	p.title.gsub!(/ los los /i, " los ")
	p.title.gsub!(/ poly /i, " Cal Poly ")
	p.title.gsub!(/ cal cal /i, " cal ")
	p.title.gsub!(/ phx /i, " phoenix ")
	p.title.gsub!(/ Ph(o|e)?(e|o)?nix /i, " Phoenix ")
	p.title.gsub!(/ Richmo(n)?d /i, " Richmond " )
	p.title.gsub!(/ redondo b\w* /i, " Redondo Beach ")	
	p.title.gsub!(/ s(anta)? ?cruz /i, " Santa Cruz ")
	p.title.gsub!(/ cruz /i, " Santa Cruz ")#It's not ok to call sc, "cruz"
	p.title.gsub!(/ santa santa /i, " santa ")#it isn't cool. 
	p.title.gsub!(/ s\w* cruz /i, " Santa Cruz ")#Google requires ,CA
	p.title.gsub!(/ sc /i, " Santa Cruz ")#Appended to the end of SC.
	p.title.gsub!(/ san f(r)?an\w* /i," SF ")
	p.title.gsub!(/ San Berna(r)?dino /i, " San Bernardino ")
	p.title.gsub!(/ mendo\w* /i, " Mendocino ")
	p.title.gsub!(/ l(a|o)s(t)? (w|v)(e|a)g(a|e)s /i, " Las Vegas ")
	p.title.gsub!(/ Humbol(d)?t /i, " Humboldt ")
	p.title.gsub!(/ ASHBY /i, "Berkeley")
	p.title.gsub!(/ pac /i, " Pacific ")
	p.title.gsub!(/ berke?le?y /i, " Berkeley ")
	p.title.gsub!(/ oak /i," oakland ")
	p.title.gsub!(/ no po/i, " North Portland ")
	p.title.gsub!(/ hts /i, " Heights ")
	p.title.gsub!(/ Bay( )?Area /i, " Bay Area ")
	p.title.gsub!(/ rohnert pk /i, " Rohnert Park ")
	p.title.gsub!(/ fraizer pk /i, " Fraizer Park ")	
	p.title.gsub!(/ 2moro /i, " Tomorrow ")
	p.title.gsub!(/ TMRW /i, " Tomorrow ")
	p.title.gsub!(/ monter(r)?(e)?y /i, " Monterey ")
	p.title.gsub!(/ Earthdance /i, " Vallejo ")
	#p.title.gsub!(/ FURTHUR /i, " Eugene ")
  p.title.gsub!(/ folsom( steet)?( fair)? /i, " SF ")
	p.title.gsub!(/ Treasure Island Music Festival /, " San Francisco ")
	p.title.gsub!(/ Hardly Strictly( Bluegrass)?( Festival)? /i, " SF ")
	p.title.gsub!(/ brc /i, " burning man ")
	p.title.gsub!(/ Wordstock /i, " Portland ")
	p.title.gsub!(/ n( )?j /i, " NJ ")
	p.title.gsub!(/ f(or)?t +worth/i, " Fort Worth ")
	p.title.gsub!(/ the playa /i, " burning man ")
	#To handle the idiolect of the pasific north west
	#The van/vancouver problem. Three of them/two of them
	p.title.gsub!(/ portland\w+ /, " pdx ")
	p.title.gsub!(/ pdx /i, " Portland ")	
	p.title.gsub!(/ n\.?e\.? /i, " NE ")
	p.title.gsub!(/vanco.?ver/i,"vancouver")
	p.title.gsub!(/ s\.?e\.? /i, " SE ")
	p.title.gsub!(/ Southern OR /i, " Southern Oregon ")
	p.title.gsub!(/ KC /i, " Kansas City ")
	p.title.gsub!(/ den /i, " Denver ")
	p.title.gsub!(/ union station /i, " UnionStation ")
	p.title.gsub!(/ b\w+ham /i, " Bellingham ")
	p.title.gsub!(/ HILLSBURRITO /i, " Hillsboro ")#Thank you #2612755112
	p.title.gsub!(/ b *-? *ham /i, " Bellingham ")
	p.title.gsub!(/ bel /i, "Bellingham")
	p.title.gsub!(/ sea /i, " Seattle ")
	p.title.gsub!(/ s(ain)?t(\.)? Louis /i, " StLouis ")
	p.title.gsub!(/ s(ain)?t(\.)? johns /i, " StJohns ")
	p.title.gsub!(/ salt ?lake( city)? /i, " SLC ")
	p.title.gsub!(/ cap\w* hill /i," Capital Hill ")
	p.title.gsub!(/ U\w* Dis\w+ /i, " University District ")
	p.title.gsub!(/ eug\w* /i, " Eugene ")
#	p.title.gsub!(/ SLC /i, " Salt Lake City ")
	p.title.gsub!(/ oly /i, " Olympia ")
	p.title.gsub!(/ tri *-? *cit\w+ /i," TriCities ")
	p.title.gsub!(/ burning man /i, " BRC ")
	
	#title = p.title#[0..60]
	dest = p.title.deprive[regex_d]
	dest.strip! if dest.is_a? String
	orig = p.title[regex_o]
	orig.strip! if orig.is_a? String
  p.title.gsub!(" ( ","(") 
	p.title.gsub!(" ) ",")")
  orig = nil if(((cities&orig.deprive.bag) - cardinals).empty?) unless orig==nil
	if(orig==nil and p.title.strip=~/(\w| )\)$/)
	  if(p.title=~/\(/)
      orig =  p.title.strip.reverse[/^\).+?\(/].reverse[1..-2]
    end
  end
  if orig!=nil
	  if(orig=~/ to /i)
	    #This section needs to be rewritten with better node balancing.
	    #For example, 2615253871, )can travel to you within Portland area) 
	    #the lnode of "to", "can travel" has less weight than the rnode,
	    #"you within Portland area"
	    #makeing 2615253871 must not break ()$s like "sf to sf to pdx"
	    #orig_ = orig
  	  i = orig.bag.index "to"
  	  orig = orig.bag[0..i-1]
  	  orig = orig.join(" ")
  	  #if(cityScore(orig,p.title)>cityScore(orig_,p.title)
    end
  	orig = orig.split(" or ")[0] if(orig=~/ or /i)
  	if(orig=~/ and /i)
  	  #and in the orig might be better handled by google
  	  andSplit = orig.split(/ and /i)
  	  orig = andSplit.sort_by{ (cities&orig.deprive.bag).length }[0]
  	  orig = nil if orig.empty?
	  end
	  if(orig!=nil)
	    orig = orig.split(" or ")[0] if(orig=~/ or /i)
  	  orig = orig.split(",")[0] #if(orig.split(",").length>2)
  	  orig = orig.bag.join(" ") if orig=~/\'/i
  	  orig = orig.split("-")[0] if orig=~/-/i
      orig = (cities&orig.deprive.bag).sort_by{ |l| p.title.bag.index(l) }      
      orig = p.city if(orig.empty?)
      orig = orig.to_a if orig.is_a? String
      orig = orig.map!{ |d| d.capitalize }.join(" ")
	  else
	    orig = p.city
    end
  else
    orig = p.city
  end
  orig = p.city if(((cities&orig.deprive.bag) - cardinals).empty?) unless orig==nil
  
  orig = p.city if(orig==/area/i)
  atEnd << p if dest==nil
  if(dest==nil)
    puts p.title.black#.sub(/#{orig}/,orig.green)    
    next
  end

  while(dest[2..-1]=~/ to /i)  
    if cityScore(dest[3..-1][regex_d],p.title)>=1
      dest = dest[3..-1][regex_d] 
    else
      dest = dest.split(/ to /i).select{|l| cityScore(l,p.title)>=1}.first
    end
    if(dest==nil)
      p.title[regex_d]=""
      dest = p.title[regex_d]
      break if(dest==nil)
    end
	end
	if(dest==nil)
	  puts p.title.black
	  next
  end
  dest.strip!
  dest = dest[0..-4] if(dest[-3..-1]==" to")
  #This issue with this regex is that it bugs out on "Tocoma" and Sac..to

	if(dest=~/ from /i)
	  from = dest.index(/ from /i)
	  dest = dest[0..from]
	end  
	#This line ranks each node of an 'or', eliminating the non-proximic locations. 	
	dest = dest.split(/ or /i).select{|l| cityScore(l,p.title)>=1}.first if dest=~/ or /i
	
	if(dest=~/ and /i)
	  #Case 1: I am going to Point A and Point B.
	  #Case 2: I am going to Point A and back. 
	  #In case one, point is the the final point, usually.   
    dest = dest.split(" and ").select{ |l| cityScore(l,p.title)>=1 }.first
  end
  if(dest==nil)
    atEnd << p
    puts p.title.black
    next
  end
  dest = dest.split(/ (via|by way of) /i)[0]
  dest = dest.split(/ leav\w+ /i)[0]
  if(dest==nil)
    puts p.title.black
    next
  end
  dest_ = dest
  dest.squeeze!(" ")
  dest = dest.split(/ from /i)[0]  
  if(p.title.deprive[regex_d]!=nil)
    #String::Deprive also removes the last () which often contains good info
    #The solution is to fix ::deprive, untill then, deprive is only called if
    #the final () doesn't contain the final dest. 
    dest = (cities&dest.deprive.bag).sort_by do |l| 
      r = p.title.deprive[regex_d].downcase.index(l.downcase) 
      #.01% of people will place their destination in the middle ()
      r = p.title[regex_d].downcase.index(l.downcase) if r==nil
      r
    end
  else
    dest = (cities&dest.deprive.bag).sort_by do |l|
       p.title[regex_d].downcase.index(l.downcase)
     end
   end
	dest = dest.map!{ |d| d.capitalize }.join(" ")
#	debugger if dest==""
#	debugger if orig.length<3  unless (orig=~/sf/i or orig=~/la/i )
=begin
  #This is somecode to deermin mre specificly where someone is going. 
  #Sometimes people will say, "I am going to AZ" and in the content say
  #Specificly they are going to tempe
	if dest.length<3  and not (dest=~/(sf|la|dc)/i or dest=="" )
	  puts "\n"
	  puts ""+"#{p.title}".underline+"#{dest}".bold.underline
	  c = cities&p.content[regex_d].deprive.bag unless p.content[regex_d]==nil
    c = cities&p.content.deprive.bag unless c
	  print  c.length>=1 ? c.length.to_s.green : "0".red
	  puts "  "+"#{p.content[regex_d]}".underline unless p.content[regex_d]==nil
	  puts "  "+(c*" ").bold unless c.empty?
	  cardinals
	  debugger
  end
	#  next
=end 
  if p.title=~/ to /i and dest == ""
    puts p.title
    p.title = p.title.gsub!(/ to /i, "") if redoLevel==0
    p.title = " to "+p.title if redoLevel==1
    if(redoLevel==2)
      p.title[/#{orig}/i]='' unless p.title[/#{orig}/i]==nil
      p.title[/ from /i]="" if p.title[/ from /i]
    end
    redoLevel += 1
    redo unless redoLevel>3
  end
  if(dest=~/vancouver/i and not dest=~/bc/i and p.city!="portland")
    dest += " bc " if(p.title=~/b(\.)?c(\.)?/i or p.content=~/b(\.)?c(\.)?/i)
    dest += " island " if(p.title=~/van\w+ island/ or p.content=~/van\w+ island/)
  end
  dest += " bc " if(dest=~/vancouver/i and p.city=="portland")
  dest = "Portland" if(dest==/port/i)
  
  dest.gsub!("Area","") unless dest=~/ ?(bay|sf) ?/i
  # if(dest=~/( Davis | LAX | Riverside | Los Angeles | Red Buff)/)
  if(dest.split.length>=3)
    #something to handle cases like 2628108272 where dest is 
    #Los Angeles Irvaheim San Diego. See below for a possible
    #solotion
  end
  #debugger
  ""
  
	print p.title.squeeze(" ").sub(/#{dest}/i,dest.red).sub(/#{orig}/i,orig.green)
  print "\n"
	origs << {:cid => p.cid, :t=>orig}
	dests << {:cid => p.cid, :t=>dest, :t_=>dest_}
  fp.write("#{p.cid},dest,#{dest}\n")
  fp.write("#{p.cid},orig,#{orig}\n")
  r = Results.find_by_cid(p.cid)
  r = Results.new if(r==nil)
  r.cid = p.cid
  r.dest = dest
  r.orig = orig
  #debugger
  r.save
  redoLevel = 0;
=begin
	url = "http://maps.googleapis.com/maps/api/geocode/json"
	#url += "?sensor=false&region=com&address="
	url += "?sensor=false&bounds=51,-96|33,-129&address="
	url += CGI::escape dest#.join(" ")
	#puts url
	#url.gsub!(",","%2C")
	res = Net::HTTP.get(URI.parse(URI::encode(url)))
	sleep(0.8)
	puts (" "*14) + "ZERO_RESULTS".black if res=~/ZERO_RESULTS/
	next if res=~/ZERO_RESULTS/
	json = JSON::Parser.new res
	json  = json.parse
	puts json if json["results"][0]["geometry"]["location"]==nil
	latlng = json["results"][0]["geometry"]["location"]
	puts " "*19 +latlng.values.reverse.join(",  ")
=end
end
#Shrink this list
#puts dests.find_all{ |o|  not o[:t]=~/(la|sf)/i and o[:t].length<5}.map{ |l| l[:t] }.uniq
#debugger
""

#Oct 12 
#605/6347.0 = 95% of posts have a destination
#6347.0/6904 = 8% of posts unfit
#Oct 13
#6238/6763 = ?
#503/6763 = 7.4% of posts unfit
=begin
require 'yaml'
require 'rubygems'
require 'ruby-debug'
#The idea for this is that sometimes we get a dest like 
#"los angeles irvaheim san diego", I want to split it up
#to be ["los angeles", "irvaheim", "san diego"]
places =  "los angeles irvaheim san diego"
#places = "los angeles santa rosa"
#places = "Seattle Anacortes Portland"
cities = YAML::load(File.open("cities.yaml").read).map{ |l| l.downcase };nil
cities += %w{ irvaheim }# Seattle } + ["Anacortes Portland"]
citiesProper = []
places.each do |place|
  cities.each do |city|
 #   debugger
    citiesProper << (place.split&city.split) #if (place.split&city.split).length>=2
  end
end
pp citiesProper.uniq
at this point, it runs in about .7 seconds, and retuns 
[[], ["los", "angeles"], ["san", "diego"], ["san"], ["los"], ["irvaheim"]]
=end
