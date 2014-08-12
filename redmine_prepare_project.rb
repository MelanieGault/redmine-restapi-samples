#!/usr/bin/env ruby

require "rest-client"
require "json"

source_project_identifier = "EXISTINGPROJECT"
new_project_identifier = "NEWPROJECT"
new_project_name = "NEW PROJECT NAME"
new_project_description = "NEW PROJECT DESCRIPTION"

redmine_url = "http://YOUR_BASE_URL"
api_key = "YOUKEY"


# get project id from project identifier (not project name!)
source_project_id = nil
response = RestClient.get "#{redmine_url}/projects.json?limit=500", { "X-Redmine-API-Key" => api_key }
project_list = JSON.parse(response.body)
project = project_list["projects"].select { |i| i['identifier'] == source_project_identifier }
raise "Error, bad project name" if (project.count != 1)
source_project_id = project.first['id']
puts "Target project : #{project.first['name']} (#{source_project_id})"

# get trakers and categories from source project
response = RestClient.get "#{redmine_url}/projects/#{source_project_identifier}.json?include=trackers,issue_categories", { "X-Redmine-API-Key" => api_key }
source_project = JSON.parse(response.body)

# get membership from source project
response = RestClient.get "#{redmine_url}/projects/#{source_project_identifier}/memberships.json", { "X-Redmine-API-Key" => api_key }
source_project_membership = JSON.parse(response.body)

# get all custom fields : need to parse to have only interesting ones
response = RestClient.get "#{redmine_url}/custom_fields.json", { "X-Redmine-API-Key" => api_key }
custom_fields = JSON.parse(response.body)

# extract customfields trackers ID and categories from source project
trackers_ids = source_project["project"]["trackers"].map { |i| i["id"]}
categories_names = source_project["project"]["issue_categories"].map { |i| i["name"]}
custom_fields_ids = custom_fields["custom_fields"].map { |i| i["id"]}

# create new child project  http://www.redmine.org/projects/redmine/wiki/Rest_Projects doc not exhaustive
archives_project = JSON.generate("project" => {"identifier" => new_project_identifier, "name" => new_project_name, "description" => new_project_description, "parent_id" => source_project_id , "tracker_ids" => trackers_ids , "inherit_members" => "0",  "is_public" => "0", "issue_custom_field_ids" => custom_fields_ids })

RestClient.post "#{redmine_url}/projects.json", archives_project, {:content_type => :json, "X-Redmine-API-Key" => api_key }

# affect categories
categories_names.each do |n|
 cname = JSON.generate("issue_category" => {"name" => "#{n}" }   )
 puts cname.to_json
 RestClient.post "#{redmine_url}/projects/#{new_project_identifier}/issue_categories.json", cname , { :content_type => :json, "X-Redmine-API-Key" => api_key }
end


# get the new id
new_project_id = nil
response = RestClient.get "#{redmine_url}/projects.json?limit=500", { "X-Redmine-API-Key" => api_key }
project_list = JSON.parse(response.body)
project = project_list["projects"].select { |i| i['identifier'] == new_project_identifier }
raise "Error, bad project name" if (project.count != 1)
new_project_id = project.first['id']
puts "New project : #{project.first['name']} (#{new_project_id})"

# get trackers and categories from new project (just to check)
response = RestClient.get "#{redmine_url}/projects/#{new_project_identifier}.json?include=trackers,issue_categories", { "X-Redmine-API-Key" => api_key }
destination_project = JSON.parse(response.body)

# affect membership
new_memberships = source_project_membership["memberships"].map { |i| i["project"]["id"]=new_project_id ; i["project"]["name"]=new_project_name ; i  }
puts new_memberships.inspect

new_memberships.each do |n|
  new_membership = JSON.generate ("memberships" => { "#{n}" } )
  puts new_membership.inspect

  RestClient.post "#{redmine_url}/projects/#{new_project_identifier}/memberships.json", new_membership , { :content_type => :json, "X-Redmine-API-Key" => api_key }
end
