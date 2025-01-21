# frozen_string_literal: true

module Views
  module Components
    extend self

    def footer(context)
      context.htmg do |scope|
        footer(class: "footer") do
          div { "© #{Time.now.year} My Roda App" } +
            div { "Built with #{a(href: "/htmg") { "HTMG" }} and Roda" }
        end
      end
    end
  end
end
