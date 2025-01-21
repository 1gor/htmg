# frozen_string_literal: true

module Views
  module Components
    extend self

    def navigation(current_user)
      htmg do
        nav(class: "main-nav") do
          ul do
            menu_items(current_user).map { |item| 
              li { a(href: item[:path]) { item[:label] } }
            }.join
          end
        end
      end
    end

    def footer
      htmg do
        footer(class: "footer") do
          div { "© #{Time.now.year} My Roda App" } +
          div { "Built with #{a(href: "/htmg") { "HTMG" }} and Roda" }
        end
      end
    end

    private

    def menu_items(current_user)
      items = [{ path: "/", label: "Home" }]
      current_user ? items + [{ path: "/about", label: "About" }] : items
    end
  end
end
