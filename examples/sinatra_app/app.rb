# frozen_string_literal: true

require 'sinatra/base'
require 'htmg'
require 'ostruct'

class SinatraApp < Sinatra::Base
  include HTMG

  # Load all view components
  Dir[File.join(__dir__, 'views/**/*.rb')].each { |f| require f }

  configure do
    set :public_folder, File.expand_path('public', __dir__)
    set :views, File.expand_path('views', __dir__)
  end

  helpers do
    def current_user
      @current_user ||= OpenStruct.new(name: "John Doe")
    end

    def menu_items
      items = [{ path: "/", label: "Home" }]
      current_user ? items + [{ path: "/about", label: "About" }] : items
    end
  end

  get '/' do
    render_page(:home)
  end

  get '/about' do
    render_page(:about)
  end

  private

  def render_page(name)
    content = -> { Views::Pages.public_send(name, self) }
    Views::Layouts.application(
      context: self,
      title: "My Sinatra App"
    ) { content.call }
  end
end
