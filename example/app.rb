# frozen_string_literal: true

require "sinatra"
require "htmg"

module LayoutHelper
  def layout(title:, &block)
    html5 do
      head {
        title { "My Site" } +
          body { header { h1 { a(href: "/") { "My Site" } } } } +
          main(&block) +
          footer do
          small {
            [ a(href: "/"){ "Home" },
              a(href: "/about") { "About" }
            ].join("&nbsp;")
          }
        end
      }
    end
  end
end

module Views
  def home_view
    h2 { "Welcome to My site" } +
      p { "This is the home page." }
  end

  def about_view
    h2 { "About Us" } +
      p { "We are a company that does things." }
  end
end

include Views
include LayoutHelper
include HTMG

get "/" do
  htmg do
    layout(title: "Home") { home_view }
  end
end

get "/about" do
  htmg do
    layout(title: "About") { about_view }
  end
end
