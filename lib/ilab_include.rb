load "exlib/rubylib_include.rb"
require 'erb'
require 'enumerator'
#if ENV['HOSTNAME'] =~ /^compute/
#  require 'external/gems/RedCloth-4.0.3/lib/redcloth'  
#else
#  require 'redcloth'
#end
require "logger"
include Test::Unit::Assertions

load 'lib/ilab_loader.rb'
load 'lib/ilab_helper.rb'
load 'lib/ilab_globals.rb'

load 'lib/extensions/ilab_extension.rb'
load 'lib/extensions/rails_extension.rb'
load 'lib/extensions/blank.rb'
load 'lib/etc/option_handler.rb'
load 'lib/etc/markup_handler.rb'
load 'lib/etc/file_handler.rb'
load 'lib/etc/trec_handler.rb'
load 'lib/etc/stat_length.rb'
load 'lib/etc/stemmer.rb'
load 'lib/field/field_helper.rb'
load 'lib/field/prm_helper.rb'
load 'lib/field/gen_helper.rb'

load 'lib/interface/gnuplot_interface.rb'
load 'lib/interface/crf_interface.rb'
load 'lib/interface/indri_interface.rb'
load 'lib/interface/r_interface.rb'
load 'lib/interface/yahoo_interface.rb'
load 'lib/interface/lda_interface.rb'
load 'lib/interface/cluster_interface.rb'

load 'lib/object/document_set.rb'
load 'lib/object/result_document_set.rb'
load 'lib/object/relevant_document_set.rb'
load 'lib/object/query_helper.rb'
load 'lib/object/query.rb'
load 'lib/object/query_set.rb'

load 'app/adhoc/pd_lib.rb'

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
