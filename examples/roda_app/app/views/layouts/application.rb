# frozen_string_literal: true

module Views
  module Layouts
    module Application
      include HTMG

      def wrap(title:, &block)
        html5 do
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
            component(:navigation) +
            main { block.call } +
            component(:footer)
          end
        end
      end

      private

      def component(name)
        Views::Components.const_get(camel_case(name.to_s)).new(current_user).render
      end

      # Basic snake_case to CamelCase conversion without ActiveSupport
      def camel_case(str)
        str.split('_').map(&:capitalize).join
      end
    end
  end
end
