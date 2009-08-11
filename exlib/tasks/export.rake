require 'ddl_include'
require 'extractor/stat_extractor'

def extract_fixture_from(table_name, o = {})
  i = "000"
  sql = "SELECT * FROM %s"
  path = o[:path] || "#{RAILS_ROOT}/test/fixtures"
  File.open("#{path}/#{table_name}.yml", 'w') do |file| 
    data = ActiveRecord::Base.connection.select_all(sql % table_name) 
    file.write data.inject({}) { |hash, record| 
      hash["#{table_name}_#{i.succ!}"] = record 
      hash 
      }.to_yaml 
  end
end

namespace :export do
  desc "Export Stat table into CSV"
  task(:stats => :environment) do
    start_at =  ENV['start_at'] || Time.now.at_beginning_of_month.to_date.to_s
    end_at = ENV['end_at'] || Time.now.to_date.to_s
    ["day","week","month"].each{|unit|export_stat_for(unit, start_at, end_at)}
  end
  
  desc 'Create YAML fixtures from data in an existing database. Defaults to development database. Set RAILS_ENV to override.' 
  task :tables => :environment do
    if ENV['table']
      extract_fixture_from(ENV['table'], ENV.to_hash.symbolize_keys)
    else
      skip_tables = ["schema_info"] 
      ActiveRecord::Base.establish_connection 
      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name| 
        extract_fixture_from(table_name, ENV.to_hash.symbolize_keys)
      end
    end
  end
end

