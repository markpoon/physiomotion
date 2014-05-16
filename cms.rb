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
end

class Section
  include Mongoid::Document
  embedded_in :page
  field :markdown, type: String
end

class CMS < Grape::API
  format :json
  helpers do
    def page() @page = Page.find_by(title: params[:page_title]) end
    def current_user
      @current_user ||= User.authorize!(params[:user_name],params[:password])
    end
    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end
    def renderer
        htmlrender = Redcarpet::Render::HTML.new(with_toc_data: true, hard_wrap: true)
        @markdown_renderer = Redcarpet::Markdown.new(htmlrender, tables: true, autolink: true)
        return @markdown_renderer
      end
    end

  resource :pages do
    params do
      requires :page_title, type: String
    end
    post do
      # authenticate!
      @page = Page.create!(title: params[:page_title]); @page
    end

    route_param :page_title do
      get do
        page.sections.collect(&:id)
      end

      params do
        requires :markdown, type: String
      end
      post do
        page.sections.create!(markdown: params[:markdown])
      end

      route_param :section_title do
        get do
          binding.pry
          # authenticate!
          renderer(page.sections[params[:section_title]].markdown)
        end

        get '/raw' do
          page.sections.find(params[:section_title]).markdown
        end

        params do
          requires :markdown, type: String
        end
        put do
          # authenticate!
          doc = page.sections[params[:section_title]].markdown = reversemarkdown.convert(params[:markdown])
          doc.save!
          markdown doc.markdown
        end
      end
    end
  end
end
