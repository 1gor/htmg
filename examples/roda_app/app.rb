# frozen_string_literal: true

require "roda"
require "htmg"

class App < Roda
  plugin :public
  plugin :render
  plugin :symbol_views

  # Load all view components
  Dir[File.join(__dir__, "views/**/*.rb")].each { |f| require f }

  route do |r|
    r.public
    
    r.root do
      view :home, layout: :application
    end

    r.on "about" do
      view :about, layout: :application
    end
  end

  def view(template, layout: nil)
    page_module = Views::Pages.const_get(template.to_s.camelize)
    content = htmg { page_module.render(self) }
    
    return content unless layout
    
    layout_module = Views::Layouts.const_get(layout.to_s.camelize)
    htmg { layout_module.wrap(title: page_module.title) { content } }
  end

  # Dummy current user for example
  def current_user
    @current_user ||= OpenStruct.new(name: "John Doe")
  end
end
