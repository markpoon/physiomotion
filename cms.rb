require 'mongoid'
require 'grape'
require 'kramdown'
require 'webster'
require 'forgery'


class User
  include Mongoid::Document
  field :name, type: String
  field :password, type: String

  def self.authenticate!(name, password)
    User.find_by(name: name).password == password
  end
end

class Page
  include Mongoid::Document
  embeds_many :sections
  field :title, type: String, default: ->{w = Webster.new; w.random_word}
  field :icon, type: String

  after_create :build_sections

  def build_sections
    3.times{ self.sections.create! } unless self.sections.nil?
  end
end

class Section
  include Mongoid::Document
  embedded_in :page
  field :markdown, type: String, default: ->{Forgery(:lorem_ipsum).words(50)}
end

class CMS < Grape::API
  format :json
  helpers do
    def page() @page = Page.find_by(title: params[:page_title]) end

    def parse(file,source="Kramdown")
      Kramdown::Document.new(file,{input:source})
    end
  end

  resource :pages do
    get do
      Page.without(:_id, :sections).entries.reject{|i|i.title=="index"}.as_json.map!{|i|i.except("_id")}
    end

    post do
      @page = Page.create!
      Page.without(:_id, :sections).entries.reject{|i|i.title=="index"}.as_json.map!{|i|i.except("_id")}
    end

    delete do
      Page.destroy_all
    end

    route_param :page_title do
      get do
        page.sections.as_json.each{|i|i.select{|j|j["_id"]}}
      end

      post do
        page.sections.create!
      end

      route_param :id do
        get do
          p = page.sections.find(params[:id]).markdown
          r = parse(p).to_html
          puts "markdown: #{p.inspect}"
          puts "html: #{r}"
          r
        end

        http_basic do |username, password|
          [username, password] == ["user", "password"]
        end

        get '/plaintext' do
          p = page.sections.find(params[:id]).markdown
          puts "markdown: #{p.inspect}"
          p
        end

        params do
          requires :markdown, type: String
        end
        put do
          s = page.sections.find(params[:id])
          s.markdown = params[:markdown]
          s.save!
          puts "params: #{params[:markdown].inspect}"
          puts "markdown: #{s.markdown.inspect}"
          s.markdown
        end

        delete do
          page.sections.find(params[:id]).destroy
        end
      end
    end
  end
end
