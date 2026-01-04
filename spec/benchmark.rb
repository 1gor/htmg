# frozen_string_literal: true

$LOAD_PATH.prepend(".")

require "lib/htmg"
require "erb"
require "benchmark"

iterations = 50_000

# Helper module to provide data
module HTMGHelper
  def title
    "HTMG Title"
  end
end

module BenchmarkCases
  include HTMG
  include HTMGHelper

  # 1. New "MatzLisp" Argument Style
  # Prediction: Faster than blocks (no instance_eval context switching)
  def htmg_arg_style
    htmg do
      html(
        body(
          h1(title), # Implicit delegation to helper
          div("Content"),
          span("More Content")
        )
      )
    end
  end

  # 2. Classic Block Style
  # Prediction: Slower due to instance_eval overhead and + concatenation
  def htmg_block_style
    htmg do
      html {
        body {
          h1 { title } +
          div { "Content" } +
          span { "More Content" }
        }
      }
    end
  end

  # 3. ERB (Cached / Production Style)
  # Prediction: Likely the fastest. ERB compiles to pure string buffering ruby code.
  ERB_TEMPLATE = ERB.new(<<-ERB)
    <html>
      <body>
        <h1><%= title %></h1>
        <div>Content</div>
        <span>More Content</span>
      </body>
    </html>
  ERB

  def erb_cached
    ERB_TEMPLATE.result(binding)
  end

  # 4. ERB (Uncached / Scripting Style)
  # Prediction: The slowest. Parsing strings is expensive.
  def erb_uncached
    template = <<-ERB
    <html>
      <body>
        <h1><%= title %></h1>
        <div>Content</div>
        <span>More Content</span>
      </body>
    </html>
    ERB
    ERB.new(template).result(binding)
  end
end

# Run the Benchmark
puts "Running #{iterations} iterations..."
puts "---------------------------------------------"

Benchmark.bm(20) do |x|
  # Create an instance to run methods within
  runner = Class.new { include BenchmarkCases }.new

  x.report("HTMG (Args):") do
    iterations.times { runner.htmg_arg_style }
  end

  x.report("HTMG (Blocks):") do
    iterations.times { runner.htmg_block_style }
  end

  x.report("ERB (Cached):") do
    iterations.times { runner.erb_cached }
  end

  x.report("ERB (Uncached):") do
    iterations.times { runner.erb_uncached }
  end
end
