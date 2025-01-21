# frozen_string_literal: true

module Views
  module Layouts
    include HTMG
    extend self

    def application(title:, &content)
      "<!DOCTYPE html>" + htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { "#{title} | My Roda App" } +
            style { <<~CSS }
              .main-nav ul { list-style: none; padding: 0 }
              .main-nav li { display: inline-block; margin-right: 20px }
              .footer { margin-top: 2rem; border-top: 1px solid #ccc }
            CSS
          } +
          body do
            Components.navigation(scope.current_user) +
            main { content.call } +
            Components.footer
          end
        end
      end
    end
  end
end
