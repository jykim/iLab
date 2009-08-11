#!/usr/bin/env ruby

# You might want to change this
ENV["RAILS_ENV"] ||= "production"

require File.dirname(__FILE__) + "/../../config/environment"
require File.dirname(__FILE__) + "/../../app/collector/collector_runner.rb"

$running = true
Signal.trap("TERM") do 
  $running = false
end
while($running) do
  $lgr.info "[collector.rb] Job started at #{Time.now}.\n"
  #begin
    run_collector()    
  #rescue Exception => e
  #  $lgr.error "[collector.rb] Unhandled exception! #{e.inspect}\n"
  #end
  $lgr.info "[collector.rb] Job finished at #{Time.now}.\n"
  sleep Source.sync_interval_default
end