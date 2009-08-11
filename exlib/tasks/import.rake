require 'ddl_include'
namespace :import do
  desc "Import Rules from File"
  task(:rules => :environment) do
    read_csv("#{RAILS_ROOT}/data/rules_jykim.csv").each do |r|
      #debugger
      next unless r[:rid]
      rule = Rule.find_or_initialize_by_rid(r[:rid])
      rule.update_attributes(r)
    end
  end
end