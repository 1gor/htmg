# frozen_string_literal: true

module Views
  module Components
    class Navigation
      include HTMG

      def initialize(current_user)
        @current_user = current_user
      end

      def render
        nav(class: "main-nav") do
          ul do
            menu_items.map { |item| li { nav_link(item) } }.join
          end
        end
      end

      private

      def menu_items
        items = [{ path: "/", label: "Home" }]
        @current_user ? items + [{ path: "/about", label: "About" }] : items
      end

      def nav_link(item)
        a(href: item[:path]) { item[:label] }
      end
    end
  end
end
