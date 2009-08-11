require 'ddl_include'
require 'collector/collector_runner'
require 'extractor/extractor_runner'
require 'extractor/batch_handler'

namespace :run do
  desc "Run collector"
  task(:collector => :environment) do
    repeat = ENV['repeat'] || 1
    1.upto(repeat.to_i){|i| run_collector(ENV.to_hash.symbolize_keys) }
  end

  namespace :extractor do
    desc "Run stat extractor"
    task(:stat => :environment) do
      start_at = ENV['start_at'] || Time.now.at_beginning_of_month.to_date.to_s
      end_at   = ENV['end_at']   || Time.now.to_date.to_s
      extract_stat_for(start_at, end_at)
    end
    
    desc "Run tag/metadata extractor"
    task(:tag => :environment) do
      start_at = ENV['start_at'] || Time.now.at_beginning_of_month.to_date.to_s
      end_at   = ENV['end_at']   || (Time.now + 86400).to_date.to_s
      condition = ["published_at >= ? and published_at < ?", start_at, end_at]
      info "[#{start_at} ~ #{end_at}]"
      Document.all(:conditions=>condition).each do |doc|
        info "Processing #{doc.title}"
        doc.process_all()
        #debugger
        #puts "published_at = #{doc.published_at}" if doc.dtype == 'calendar'
        doc.save!
        puts "published_at = #{doc.published_at}" if doc.dtype == 'calendar'
      end
    end
  end
  
  task(:batch => :environment) do
    enque_daily_job()
    Rake::Task['jobs:work'].execute  
  end
end