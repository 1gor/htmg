# frozen_string_literal: true

require "htmg"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

module LayoutHelper
  include HTMG

  # Define the layout as a method that accepts title, header, and content
  def layout(title:, header:, content:)
    htmg do
      html do
        head { meta(title: title) } +
          body { header { header } + main { content } }
      end
    end
  end

  # Helper to define the header section
  def header
    htmg do
      ul(class: "nav") {
        [:foo, :bar].map { |n| li { "menu #{n}" } }.join
      }
    end
  end

  # Helper to define the content section
  def content(title)
    htmg do
      h1(class: "article-title") { title } +
        div(class: "text-black") { "Contents of the first article" }
    end
  end
end
