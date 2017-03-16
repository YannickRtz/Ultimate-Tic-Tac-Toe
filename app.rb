# This is the Main-File
# of my Sinatra-Application

# Required Gems:
require 'sinatra'
require 'sinatra/activerecord' # Needs activerecord-mysql-adapter
require 'sass'
require 'json'
require 'haml'

# My own Codes:
Dir['./controllers/*'].each do |file|
  require file
end
require './general_helpers.rb'
require './models.rb'
require './uttt_helpers.rb'

# Environment-Configuration
configure(:production) do
  set :environment, :production
end
configure(:development) do
  set :environment, :development
end

# Database-Setup:
ActiveRecord::Base.establish_connection(
  :adapter  => "mysql",
  :host     => "localhost",
  :username => "DBUSER",
  :password => "DBPASSWORD",
  :database => "DBNAME"
)

# 404 Catch and error handling:
error do
  'Sorry there was an error - ' + env['sinatra.error'].name
end

get '*' do
  404
  'Error 404 - Not found'
end