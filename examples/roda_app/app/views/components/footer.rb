# frozen_string_literal: true

module Views
  module Components
    include HTMG
    extend self

    def footer(context)
      context.htmg do |scope|
        div(class: "footer") do
          small do
            "© #{Time.now.year} My Roda App"
          end
        end
      end
    end
  end
end
