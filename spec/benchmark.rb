# frozen_string_literal: true

$LOAD_PATH.prepend(".")

require "lib/htmg"
require_relative "layout_helper_erb"
require_relative "layout_helper"
require "benchmark"

title = "My article title"

iterations = 10_000

Benchmark.bm do |x|
  include LayoutHelper  # Your HTMG-based layout
  include LayoutHelperERB  # ERB-based layout

  x.report("HTMG Generator:") do
    iterations.times do
      layout(title: title)
    end
  end

  x.report("ERB Generator:") do
    iterations.times do
      layout_erb(title: title, header: header_erb, content: content_erb(title))
    end
  end
end
