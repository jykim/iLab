#Constants with Global Scope

PTN_WORD = /[a-z][\w-]*/
PTN_EMPTY = /\A\s*\Z/   # Empty Line
PTN_LINE = /^.*$/
PTN_LINE_SKIP = /^#.*$/ # Skippable(commented) Line

SEP_LINE = /(?:\r\n|\n|\r)/
SEP_SENTENCE = /\. (?=[A-Z])/
SEP_ITEM = /,|\t/

MAX_NUM = 9999999 # Max. value of Range
MIN_NUM = -9999999 # Max. value of Range
INVALID_NUM = -1

ENV['RAILS_ROOT'] = '/home/lifidea/rails/lifidea' if !ENV['RAILS_ROOT']
PATH_DATA = File.join( ENV['RAILS_ROOT'],"data" )
PATH_LOG  = File.join( ENV['RAILS_ROOT'],"log" )
PATH_TMP  = File.join( ENV['RAILS_ROOT'],"tmp" )

require "globals/global"

#def empty? str
#  str.blank?
#end

#Application Frameworks
#
module ApplicationFramework

=begin rdoc
  Tag Processing
=end
  # Initialize Applications
  def init_app
    
  end

  def init_logger( file_name , o = {} )
    #Initiate Logger
    #if File.exist?(file_name)
    #  system("cat #{file_name}. #{file_name} > #{file_name}.bak")
    #  File.delete(file_name)
    #end
    level = 
    path  = o[:path]  || PATH_LOG
    $lgr = Logger.new( File.join(path,file_name) )
    $lgr.level = o[:level] || Logger::INFO
    $lgr.datetime_format = "[%Y%m%d %H%M%S]"
  end
end
