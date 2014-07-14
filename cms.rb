require 'mongoid'
require 'grape'
require 'kramdown'

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
  field :title, type: String
  field :icon, type: String
end

class Section
  include Mongoid::Document
  embedded_in :page
  field :title, type: String
  field :markdown, type: String
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
      Page.without(:_id, :sections).entries.as_json
    end

    params do
      requires :page_title, type: String
      requires :icon, type: String
    end
    post do
      # authenticate!
      @page = Page.create!(title: params[:page_title]..gsub(" ", "_"), icon: params[:icon])
    end

    delete do
      Page.destroy_all
    end

    route_param :page_title do
      get do
        page.sections.as_json.each{|i|i.except!("_id", "markdown")}
      end

      params do
        requires :title, type: String
        requires :markdown, type: String
      end
      post do
        page.sections.create!(markdown: params[:markdown], title: params[:title])
      end

      route_param :title do
        get do
          p = page.sections.find_by(title: params[:title]).markdown
          r = parse(p).to_html
          puts "markdown: #{p.inspect}"
          puts "html: #{r}"
          r
        end

        http_basic do |username, password|
          [username, password] == ["user", "password"]
        end

        get '/plaintext' do
          p = page.sections.find_by(title: params[:title]).markdown
          puts "markdown: #{p.inspect}"
          p
        end

        params do
          requires :markdown, type: String
        end
        put do
          s = page.sections.where(title: params[:title]).entries.first
          # s.markdown = parse(params[:markdown],"Html").to_kramdown
          s.markdown = params[:markdown]
          s.save!
          puts "params: #{params[:markdown].inspect}"
          puts "markdown: #{s.markdown.inspect}"
          s.markdown
        end

        delete do
          page.sections.find_by(title: params[:title]).destroy
        end
      end
    end
  end
end
