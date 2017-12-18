#!/usr/bin/env ruby
# encoding: UTF-8
#
# Ce script utilise l'API REST de Redmine pour créer des Version en masse sur un projet
#
# Auteur : DMA 17/04/2015
 
require 'rubygems'
require 'active_resource'
 
# simule les actions (A CHANGER pour un vrai run)
dry_run = true
 
# date de l'annee  (A CHANGER pour un vrai run)
year = 2015
 
# premiere semaine à générer  (A CHANGER pour un vrai run)
first_week = 31
 
# dernière semaine à génerer  (A CHANGER pour un vrai run)
last_week = 53
 
# authentification sur Redmine  (A CHANGER pour un vrai run)
Redmine_project = 'https://REDMINE_URL/projects/unix'
Redmine_apikey = 'mon_api_key'
 
Month = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre']
 
# Déclaration de la ressource REST dans Redmine
class Version < ActiveResource::Base
  self.site = Redmine_project
  self.user = Redmine_apikey
  self.format = :xml
end
 
puts "dry run" if dry_run
 
first_week.upto(last_week) do |week_number|
  first_day_of_week = Date.commercial( year, week_number, 1)
  last_day_of_week = Date.commercial( year, week_number, 5)
  displayed_year = last_day_of_week.strftime("%Y").to_i
  displayed_week = (displayed_year > year ? "01" : week_number)
  month_of_last_day = Month[last_day_of_week.mon-1]
  label = "#{displayed_year}-#{displayed_week} (#{first_day_of_week.strftime("%-d")} au #{last_day_of_week.strftime("%-d")} #{month_of_last_day})"
  puts label
 
  # utilise l'API REST de Redmine pour créer la version
  unless dry_run
    puts "create version !"
    version = Version.new
    version.name = label
    version.due_date = last_day_of_week
    version.save
  end
end
