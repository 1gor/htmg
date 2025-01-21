# frozen_string_literal: true

module Views
  module Pages
    class Home
      include HTMG

      def initialize(context)
        @context = context
      end

      def self.title = "Welcome"

      def render
        article do
          h1 { "Hello, #{@context.current_user.name}!" } +
          p { "This is the home page of our Roda application." } +
          ul(class: "features") {
            %w[Fast Secure HTMG-powered].map { |f| li { f } }.join
          }
        end
      end
    end
  end
end
