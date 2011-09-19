#This is the start of a template for testing classifier accuracy with either 10 fold cross analysis, or one out.


require 'rubygems'
require 'classifier'
require 'pp'
require './colors.rb'
require 'ruby-debug'

#order of classification should run -> 
  #fit/unfit
  #location
  #wanted/offered  
  #chronemics
  

class Array
  def avrg
    self.inject(0){ |n,sum| sum+=n }/self.length 
  end
end
def line(x=79,m=:bold)
	 puts (("#"*x)).send(m)
end

train3 = File.open("train3.csv").read.split("\n").collect do |t| 
  { 
    :classification => t.split(",")[0].downcase.to_sym,
    :text => t.split(",")[1..2].join("  ")
  }
end
train3 = train3.reject{ |t| t[:classification]==:other  } 
train3 = train3.sort_by{ rand }
#Method: 1 out, and 10 fold. 
#1 out uses all but one for training data, and tests one
#10 fold uses all but 1/10 for training data, and tests 1/10th
METHOD = :tenFold #:tenFold
PRINTMISTAKES = true
if METHOD==:oneOut
  offset = 1 
  start = 0 
  tail = offset-1
  times = acc = [0]*train3.length
end
if METHOD ==:tenFold
  offset = train3.length/10
  start = 0 
  tail = offset
  times = acc = [0]*10
end
startTime = Time.now
times.collect! do 
  verif = train3[start..tail]
  begin
  trainingData = train3 - verif
  rescue TypeError
    debugger
  end
  #make a classifier
  lsi = Classifier::LSI.new 
  trainingData.each do |datum|
    #train the classifier
    lsi.add_item(datum[:text],datum[:classification]) 
  end
  acc= 0
  print "#{train3.index(verif[0])} .. #{train3.index(verif[1])}: #{verif.length}"
  miscategorized = []
  verif.map do |ver|
    #classify ver, store in resp
    resp = lsi.classify ver[:text] 
    unless(resp.to_s.downcase.to_sym==ver[:classification])
      ver[:mis] = resp.to_s.downcase.to_sym
      miscategorized << ver
    end
    acc+= 1 if(resp.to_s.downcase.to_sym==ver[:classification])
  end
  #puts Time.now-startTime
  thisAcc = ((acc.to_f/verif.length)*100)
  printf("%15.2f%% accurate\n", thisAcc)
  if PRINTMISTAKES
    miscategorized.each do |mis|
      print mis[:mis].to_s.upcase.bold.red+ "\t"
      puts mis[:text].red
      line(79,"yellow")
    end
  end
  start = tail + (METHOD==:oneFold ? 0 : 1)
  tail += offset
  tail = -1 if tail>train3.length 
  thisAcc
end
printf("Overall accuracy %3.5f%%\n".bold,  times.avrg)
