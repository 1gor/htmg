# frozen_string_literal: true

module Views
  module Pages
    include HTMG
    extend self

    def home(context)
      htmg do |scope|
        article do
          h1 { "Hello, #{context.current_user.name}!" } +
          p { "This is the home page of our Roda application." } +
          ul(class: "features") {
            %w[Fast Secure HTMG-powered].map { |f| li { f } }.join
          }
        end
      end
    end

    def about(context)
      htmg do
        article do
          h1 { "About Our App" } +
          p { "Learn more about our amazing application" }
        end
      end
    end
  end
end
