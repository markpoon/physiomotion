require "sinatra/base"
require "slim"

if settings.development?
  require "sinatra/reloader"
  require 'benchmark'
  require 'pry'
end

enable :sessions

module Sinatra
  module LoginHelper

    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Access Denied. Access To This Resource Is Unauthorized.\n"
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      cred = ['margit', 'tipsy wombats']

      if session[:login] and session[:password]
        if cred == [session[:login], session[:password]]
          true
        else
          false
        end
      elsif @auth.provided? and @auth.basic? and @auth.credentials
        if @auth.credentials == cred
          session[:login], session[:password] = @auth.credentials
          true
        else
          false
        end
      else
        false
      end
    end
  end
  helpers LoginHelper
end

class Application < Sinatra::Base
  helpers Sinatra::LoginHelper
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

  get '/' do
    slim :index
  end

  get '/login' do
    authorized?
  end

  get '/logout' do
    session = {}
  end

  get '/md/:filename' do
    markdown params[:filename].intern
  end

  get '/markdown/:filename' do
    protected!
    Rack::Utils.escape_html File.read("./views/" + params[:filename] + ".md")
  end

  post '/markdown/:filename' do
    protected!
    filename = "./views/" + params[:filename] + ".md"
    File.open(filename,'w') do |file|
      file.write params[:markdown]
    end
    markdown params[:filename].intern
  end

  get '/:filename' do
    slim params[:filename].intern 
    #|| halt(404,params[:filename]+".slim not found")
  end

  # select names that end with .md from the views folder and strip them of their
  # endings, each into symbols and pass them through the markdown engine
  # then join them into a single page view using the slim layout

  # get '/' do
  #   slim Dir.entries("./views").select{|name| name.match /.md\z/}
  #   .map{|name| name.sub ".md", ""}.map(&:to_sym)
  #   .map{|name| markdown name}.join
  # end

  get '/css/:name.css' do
    content_type 'text/css', charset: 'utf-8'
    scss(:"/sass/#{params[:name]}")
  end
end
