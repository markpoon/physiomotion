require "sinatra/base"
require "slim"
require "mongoid"
Mongoid.load! "./mongoid.yml"

if development?
  require "sinatra/reloader"
  require 'benchmark'
  require 'pry'
end

class Site < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
    include Benchmark
    Bundler.require(:development)
    get '/binding' do
      Binding.pry
    end
  end

  configure :production do
    Bundler.require(:production)
  end

  get '/scripts/cms.js' do
    coffee :cms
  end

  get '/css/:name.css' do
    content_type 'text/css', charset: 'utf-8'
    scss(:"/sass/#{params[:name]}")
  end

  get '/*' do
    slim :index
  end
end
