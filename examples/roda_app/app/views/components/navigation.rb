# frozen_string_literal: true

module Views
  module Components
    extend self

    def navigation(context)
      context.htmg do |scope|
        nav(class: "main-nav") do
          ul do
            scope.menu_items(scope.current_user).map { |item|
              li { a(href: item[:path]) { item[:label] } }
            }.join
          end
        end
      end
    end


  end
end
