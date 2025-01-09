# frozen_string_literal: true

$LOAD_PATH.prepend(".")

require "lib/htmg"
require "erb"
require "benchmark"

iterations = 100_000

# Define minimal structure in HTMG with data
module SimpleHTMGWithData
  include HTMG

  def simple_htmg_structure_with_data
    htmg do |scope|
      html do
        body do
          h1 { scope.title } +  # Use data from external scope
          div { "Content" } +
          span { "More Content" }
        end
      end
    end
  end
end

# Helper module to provide data for HTMG
module HTMGHelper
  def title
    "HTMG Title"
  end
end

# Define minimal structure in ERB with data
module SimpleERBWithData
  def simple_erb_structure_with_data(title)
    template = <<-ERB
    <html>
      <body>
        <h1><%= title %></h1>  <!-- Use external data -->
        <div>Content</div>
        <span>More Content</span>
      </body>
    </html>
    ERB

    ERB.new(template).result(binding)
  end
end

# Minimal benchmark test
Benchmark.bm do |x|
  include SimpleHTMGWithData
  include HTMGHelper
  include SimpleERBWithData

  x.report("HTMG with Data:") do
    iterations.times do
      simple_htmg_structure_with_data
    end
  end

  x.report("ERB with Data:") do
    iterations.times do
      simple_erb_structure_with_data("ERB Title")
    end
  end
end
