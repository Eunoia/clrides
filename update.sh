cd craigslist-enhancement-suite 
ruby clCache.rb &&
ruby DichotomyDichotomy.rb && 
ruby destinationEstimation.rb &&
ruby chronemics.rb &&
cp -v posts.sql ../NodeStuff/posts.sql &&
cp -v posts.sql ../salt/posts.sql
