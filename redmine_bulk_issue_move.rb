#!/usr/bin/env ruby

require "rest-client"
require "json"
require "optparse"

# gestion des options de la ligne de commande
move = false
target_project_identifier = ""
query_url = ""
redmine_url = ""
api_key = "" 
OptionParser.new do |opts|
  opts.banner = "Usage: redmine_bulk_issue_move.rb [options]"
  opts.separator ""
  opts.on("-t","--target IDENTIFIER", "Target project identifier") { |param| target_project_identifier = param }
  opts.on("-q","--query_url URL", "Redmine query URL") { |param| query_url = param }
  opts.on("-r","--redmine-url URL", "Redmine base URL") { |param| redmine_url = param}
  opts.on("-a","--api-key API", "API key") { |param| api_key = param}
  opts.on("--move", "Move issue to target project") { move = true }
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit 0
  end
end.parse!(ARGV)

# get project id from project identifier (not project name!)
target_project_id = nil
response = RestClient.get "#{redmine_url}/projects.json?limit=500", { "X-Redmine-API-Key" => api_key }
json = JSON.parse(response.body)
project = json["projects"].select { |i| i['identifier'] == target_project_identifier }
raise "Error, bad project name" if (project.count != 1)
target_project_id = project.first['id']
puts "Target project : #{project.first['name']} (#{target_project_id})"

# get issue id list from query (CSV format)
response = RestClient.get query_url, { "X-Redmine-API-Key" => api_key }
response.body.split(/\n/).each do |line|
  id, subject = line.split(/;/)
  # ignore issue id if not numeric (ie column header)
  next unless id =~ /[0-9]+/
  
  # get issue details
  issue = RestClient.get "#{redmine_url}/issues/#{id}.json", { "X-Redmine-API-Key" => api_key }
  json = JSON.parse(issue.body)
  # ignore issue if already in target project (userful for nested projects)
  next if json['issue']['project']['id'] == target_project_id
  puts "#{id} #{subject}"
  
  # create JSON and update issue 
  if move
    new_json = JSON.generate("issue" => {"project_id" => target_project_id} )
    RestClient.put "#{redmine_url}/issues/#{id}.json", new_json, {:content_type => :json, "X-Redmine-API-Key" => api_key }
  end
  
end
