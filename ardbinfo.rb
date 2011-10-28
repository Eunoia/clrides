#This file contains information about the databases in the Enhancement Suite. 
#Placeing the information in one file avoids bugs that come from incongruent Active Record Information information
#
#
#
module Database
ActiveRecord::Base.establish_connection(
		  :adapter => "sqlite3",
		  #:dbfile  => ":memory:"
		  :database => "posts.sql"
)

class Posts < ActiveRecord::Base
   validates_uniqueness_of :cid
   set_primary_key :cid
#   has_one(:result, {:foreign_key => :cid , :primary_key => :cid })
end
class Results < ActiveRecord::Base
   validates_uniqueness_of :cid
   set_primary_key :cid
#   belongs_to(:posts,{ :foreign_key => :cid, :primary_key => :cid})
end
end
