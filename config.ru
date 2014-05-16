require "bundler/setup"
Bundler.require(:default)

if ENV["RACK_ENV"] == 'development' or ENV["RACK_ENV"] == 'test'
  require 'pry-rescue'
  use PryRescue::Rack
end

require './app'
require './cms'

run Rack::Cascade.new [CMS, Site]
