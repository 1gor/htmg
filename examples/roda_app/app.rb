# frozen_string_literal: true

require "roda"
require "htmg"
require "ostruct"

class App < Roda
  include HTMG

  plugin :public
  # Load all view components
  Dir[File.join(__dir__, "app/views/**/*.rb")].each { |f| require f }

  route do |r|
    r.public

    r.root do
      render_page(:home)
    end

    r.on "about" do
      render_page(:about)
    end
  end

  def render_page(name)
    content = -> { Views::Pages.public_send(name, self) }
    Views::Layouts.application(
      context: self,
      title: "My Roda App"
    ) { content.call }
  end

  # Dummy current user for example
  def current_user
    @current_user ||= OpenStruct.new(name: "John Doe")
  end


  private

  # Basic snake_case to CamelCase conversion without ActiveSupport
  def camel_case(str)
    str.split('_').map(&:capitalize).join
  end

end
