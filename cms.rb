require 'mongoid'
require 'grape'

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
    def authenticate!
      binding.pry
      error!('401 Unauthorized', 401) unless current_user
    end
    def page() @page = Page.find_by(title: params[:page_title]) end
    def renderer
      unless @renderer
        h = Redcarpet::Render::HTML.new(with_toc_data: true, hard_wrap: true)
        @renderer = Redcarpet::Markdown.new(h, tables: true, autolink: true)
      end
      return @renderer
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
          renderer.render(page.sections.find_by(title: params[:title]).markdown).gsub("\n","")
        end

        http_basic do |username, password|
          [username, password] == ["user", "password"]
        end

        get '/raw' do
          page.sections.find_by(title: params[:title]).markdown.gsub("\n\n","\n").gsub("\n","<br>")
        end

        delete do
          page.sections.find_by(title: params[:title]).destroy
        end

        params do
          requires :markdown, type: String
        end
        put do
          section = page.sections.where(title: params[:title]).entries.first
          section.markdown = ReverseMarkdown.convert(params[:markdown]).gsub("\n", "\n\n")
          section.save!
          renderer.render(section.markdown)
        end
      end
    end
  end
end
