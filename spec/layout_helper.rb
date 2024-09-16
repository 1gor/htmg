# frozen_string_literal: true

module LayoutHelper
  include HTMG

  # Define the layout as a method that accepts title, header, and content
  def layout(title:)
    htmg do |scope|
      html do
        head { meta(title: title) } + body { header { scope.header_section } + main { scope.content_section(title) } }
      end
    end
  end

  # Helper to define the header section
  def header_section
    htmg do
      ul(class: "nav") {
        [:foo, :bar].map { |n| li { "menu #{n}" } }.join
      }
    end
  end

  # Helper to define the content section
  def content_section(title)
    htmg do
      h1(class: "article-title") { title } +
        div(class: "text-black") { "Contents of the first article" }
    end
  end
end
