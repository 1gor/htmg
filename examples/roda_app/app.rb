# frozen_string_literal: true

require "roda"
require "htmg"

class App < Roda
  include HTMG
  
  plugin :public
  plugin :render
  plugin :symbol_views

  # Load all view components
  Dir[File.join(__dir__, "app/views/**/*.rb")].each { |f| require f }

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
    page_module_name = camel_case(template.to_s)
    page_module = Views::Pages.const_get(page_module_name)
    content = htmg { page_module.render(self) }

    return content unless layout

    layout_module_name = camel_case(layout.to_s)
    layout_module = Views::Layouts.const_get(layout_module_name)
    htmg { layout_module.wrap(title: page_module.title) { content } }
  end

  private

  # Basic snake_case to CamelCase conversion without ActiveSupport
  def camel_case(str)
    str.split('_').map(&:capitalize).join
  end

  # Dummy current user for example
  def current_user
    @current_user ||= OpenStruct.new(name: "John Doe")
  end
end
