# frozen_string_literal: true

module Views
  module Layouts
    include HTMG
    extend self

    def minimal(context:, title:, &content)
      "<!DOCTYPE html>" + context.htmg do |scope|
        html do
          head {
            meta(charset: "utf-8") +
            title { title }
          } +
          body { content.call }
        end
      end
    end
  end
end
